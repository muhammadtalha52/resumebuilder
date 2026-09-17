import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/conversation_models.dart';
import '../../utils/secure_keys.dart';
import 'transcriber_interface.dart';

class AssemblyAiAudioTranscriber extends AudioTranscriber {
  static const _sampleRate = 16000;
  static const _bytesPerFrame = 3200; // 100 ms of 16 kHz mono PCM16

  final _recorder = AudioRecorder();
  final _pending = BytesBuilder(copy: false);
  final _speakerNumbers = <String, int>{};
  
  WebSocketChannel? _channel;
  StreamSubscription<Uint8List>? _audio;
  Completer<void>? _terminated;
  int _lastSpeaker = 1;

  // State management
  TranscriptionState _state = TranscriptionState.idle;
  
  final List<SpeakerSegment> _speakerSegments = [];
  String _latestSegment = '';
  int _chunkCount = 0;

  // ==================== INTERFACE GETTERS ====================

  @override
  TranscriptionState get state => _state;

  @override
  String get transcript => speakerSegments.map((c) => '[Speaker ${c.speakerId + 1}]: ${c.text}').join('\n\n');

  @override
  String get rawTranscript => transcript;

  @override
  String get latestSegment => _latestSegment;

  @override
  bool get isRecording => _state == TranscriptionState.recording;

  @override
  int get chunkCount => _chunkCount;

  @override
  int get pendingChunks => 0; // Real-time streaming

  @override
  List<SpeakerSegment> get speakerSegments => List.unmodifiable(_speakerSegments);

  @override
  int get speakerCount => _speakerNumbers.length;

  // ==================== INTERNAL STATE UPDATES ====================

  void _updateState(TranscriptionState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  // ==================== LIFECYCLE METHODS ====================

  @override
  Future<bool> initialize() async {
    _updateState(TranscriptionState.initializing);
    try {
      if (!await _recorder.hasPermission()) {
        _updateState(TranscriptionState.error);
        return false;
      }
      _updateState(TranscriptionState.idle);
      return true;
    } catch (e) {
      debugPrint('[AssemblyAI] Init error: $e');
      _updateState(TranscriptionState.error);
      return false;
    }
  }

  @override
  Future<void> startRecording() async {
    if (_state == TranscriptionState.recording) return;
    _updateState(TranscriptionState.initializing);

    try {
      final apiKey = await SecureKeys.getAssemblyAiKey();

      final uri = Uri(
        scheme: 'wss',
        host: 'streaming.assemblyai.com',
        path: '/v3/ws',
        queryParameters: {
          'sample_rate': '$_sampleRate',
          'encoding': 'pcm_s16le',
          'format_turns': 'true',
          'speech_model': 'universal-streaming-english',
          'speaker_labels': 'true',
          'token': apiKey,
        },
      );

      final channel = WebSocketChannel.connect(uri);
      await channel.ready; // throws if connection fails
      _channel = channel;
      _terminated = Completer<void>();

      channel.stream.listen(
        _onMessage,
        onError: (Object e) {
          debugPrint('[AssemblyAI] socket error: $e');
          _updateState(TranscriptionState.error);
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('[AssemblyAI] socket closed');
          if (!(_terminated?.isCompleted ?? true)) _terminated!.complete();
          if (_state == TranscriptionState.recording) {
            _updateState(TranscriptionState.error);
            _handleDisconnect();
          } else {
            _updateState(TranscriptionState.stopped);
          }
        },
      );

      final pcm = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
      ));

      _audio = pcm.listen((chunk) {
        _chunkCount++;
        _pending.add(chunk);
        if (_pending.length >= _bytesPerFrame) {
          _channel?.sink.add(_pending.takeBytes());
        }
      });

      _updateState(TranscriptionState.recording);
    } catch (e) {
      debugPrint('[AssemblyAI] Start recording error: $e');
      _updateState(TranscriptionState.error);
    }
  }

  void _onMessage(dynamic message) {
    if (message is! String) return;
    final data = jsonDecode(message) as Map<String, dynamic>;

    if (data['type'] == 'Termination') {
      if (!(_terminated?.isCompleted ?? true)) _terminated!.complete();
      return;
    }
    
    if (data['type'] != 'Turn') return;

    final text = ((data['transcript'] as String?) ?? '').trim();
    if (text.isEmpty) return;

    final endOfTurn = data['end_of_turn'] == true;
    
    // An ended turn arrives twice: first without punctuation, then formatted. Keep only the formatted one.
    if (endOfTurn && data['turn_is_formatted'] != true) return;

    final speakerId = _speakerFor(data['speaker_label'] as String?);

    if (endOfTurn) {
      _speakerSegments.add(SpeakerSegment(
        speakerId: speakerId,
        text: text,
      ));
      _latestSegment = ''; // Clear live text
    } else {
      _latestSegment = text; // Update live text
    }

    notifyListeners();
  }

  /// "A", "B", ... become 0, 1, ... in the order people first speak.
  /// Subtracted 1 to match the zero-indexed SpeakerSegment logic in conversation_models.
  int _speakerFor(String? label) {
    final key = (label ?? '').trim().toUpperCase();
    if (key.isEmpty || key == 'PENDING' || key == 'UNKNOWN') return _lastSpeaker - 1;
    final speakerNumber = _speakerNumbers.putIfAbsent(key, () => _speakerNumbers.length + 1);
    _lastSpeaker = speakerNumber;
    return speakerNumber - 1;
  }

  void _handleDisconnect() {
    if (_state != TranscriptionState.recording) return;
    debugPrint('[AssemblyAI] Disconnected, attempting to reconnect...');
    _channel = null;
    _audio?.cancel();
    _audio = null;
    _recorder.isRecording().then((isRec) {
      if (isRec) _recorder.stop();
    });
    
    // Retry connection after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (_state == TranscriptionState.recording || _state == TranscriptionState.error) {
        // Reset state and try starting again
        _state = TranscriptionState.idle;
        startRecording();
      }
    });
  }

  @override
  Future<void> stopRecording() async {
    _updateState(TranscriptionState.processing);
    
    await _audio?.cancel();
    _audio = null;
    if (await _recorder.isRecording()) await _recorder.stop();
    _pending.clear();

    final channel = _channel;
    _channel = null;
    
    if (channel != null) {
      try {
        channel.sink.add(jsonEncode({'type': 'Terminate'}));
        await _terminated?.future.timeout(const Duration(seconds: 5), onTimeout: () {});
      } catch (e) {
        debugPrint('[AssemblyAI] Termination error: $e');
      } finally {
        await channel.sink.close();
      }
    }
    
    _updateState(TranscriptionState.stopped);
  }

  @override
  void dispose() {
    if (_audio != null) {
      _audio?.cancel();
    }
    if (_channel != null) {
      _channel?.sink.close();
    }
    _recorder.dispose();
    super.dispose();
  }
}
