import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:skillresy/utils/secure_keys.dart';

import 'transcriber_interface.dart';
import 'transcription_config.dart';

/// Deepgram real-time transcription implementation
///
/// Provides true word-by-word streaming transcription with:
/// - Lower latency (~200-300ms)
/// - No commit/wait logic needed
/// - Better accuracy for continuous speech
/// - Simpler implementation
///
/// Uses Deepgram's Nova-2 model for high accuracy transcription.
class DeepgramAudioTranscriber extends AudioTranscriber {
  // WebSocket connection
  WebSocket? _webSocket;
  bool _isConnected = false;

  // Audio recording with flutter_sound
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  StreamController<Uint8List>? _recordingDataController;
  bool _isRecorderInitialized = false;

  // State management
  TranscriptionState _state = TranscriptionState.idle;
  String _fullTranscript = '';
  String _interimTranscript = '';
  String _latestWord = '';
  bool _isDisposed = false;
  int _wordCount = 0;

  // Timers and control
  Timer? _keepAliveTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  // Configuration from TranscriptionConfig
  late final String _model;
  late final String _language;
  late final String _encoding;
  late final int _sampleRate;
  late final int _channels;
  late final bool _interimResults;
  late final bool _punctuate;
  late final bool _smartFormat;
  late final bool _diarize;
  late final int _endpointing;
  late final int _utteranceEndMs;
  late final bool _vadEvents;
  late final bool _fillerWords;
  late final int _maxReconnectAttempts;
  late final int _reconnectDelayMs;
  late final int _keepAliveIntervalMs;

  DeepgramAudioTranscriber() {
    final config = TranscriptionConfig.deepgramConfig;
    _model = config['model'] as String;
    _language = config['language'] as String;
    _encoding = config['encoding'] as String;
    _sampleRate = config['sampleRate'] as int;
    _channels = config['channels'] as int;
    _interimResults = config['interimResults'] as bool;
    _punctuate = config['punctuate'] as bool;
    _smartFormat = config['smartFormat'] as bool;
    _diarize = config['diarize'] as bool;
    _endpointing = config['endpointing'] as int;
    _utteranceEndMs = config['utteranceEndMs'] as int;
    _vadEvents = config['vadEvents'] as bool;
    _fillerWords = config['fillerWords'] as bool;
    _maxReconnectAttempts = config['maxReconnectAttempts'] as int;
    _reconnectDelayMs = config['reconnectDelayMs'] as int;
    _keepAliveIntervalMs = config['keepAliveIntervalMs'] as int;
  }

  // ==================== INTERFACE GETTERS ====================

  @override
  TranscriptionState get state => _state;

  @override
  String get transcript {
    if (_interimTranscript.isNotEmpty) {
      return '$_fullTranscript $_interimTranscript'.trim();
    }
    return _fullTranscript;
  }

  @override
  String get rawTranscript => _fullTranscript;

  @override
  String get latestSegment => _latestWord;

  @override
  bool get isRecording => _state == TranscriptionState.recording;

  @override
  int get chunkCount => _wordCount;

  @override
  int get pendingChunks => 0;

  // ==================== INITIALIZATION ====================

  @override
  Future<bool> initialize() async {
    _setState(TranscriptionState.initializing);

    try {
      await _recorder.openRecorder();
      _isRecorderInitialized = true;
      _setState(TranscriptionState.idle);
      return true;
    } catch (e) {
      _logError('Initialization failed: $e');
      _setState(TranscriptionState.error);
      return false;
    }
  }

  // ==================== RECORDING CONTROL ====================

  @override
  Future<void> startRecording() async {
    if (_state == TranscriptionState.recording) return;

    _resetState();
    _setState(TranscriptionState.recording);

    try {
      await _connectWebSocket();
      await _startAudioStream();
      _startKeepAliveTimer();
    } catch (e) {
      _logError('Failed to start recording: $e');
      _setState(TranscriptionState.error);
      await _cleanup();
    }
  }

  @override
  Future<void> stopRecording() async {
    _isDisposed = true;

    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _stopAudioStream();
    await _closeWebSocket();

    _setState(TranscriptionState.stopped);
  }

  // ==================== WEBSOCKET CONNECTION ====================

  Future<void> _connectWebSocket() async {
    try {
      final apiKey = await SecureKeys.getDeepgramKey();

      final queryParams = {
        'model': _model,
        'language': _language,
        'encoding': _encoding,
        'sample_rate': _sampleRate.toString(),
        'channels': _channels.toString(),
        'interim_results': _interimResults.toString(),
        'punctuate': _punctuate.toString(),
        'smart_format': _smartFormat.toString(),
        'diarize': _diarize.toString(),
        'endpointing': _endpointing.toString(),
        'utterance_end_ms': _utteranceEndMs.toString(),
        'vad_events': _vadEvents.toString(),
        'filler_words': _fillerWords.toString(),
      };

      final uri = Uri.parse(
        'wss://api.deepgram.com/v1/listen',
      ).replace(queryParameters: queryParams);

      _webSocket = await WebSocket.connect(
        uri.toString(),
        headers: {'Authorization': 'Token $apiKey'},
      ).timeout(const Duration(seconds: 10));

      _isConnected = true;

      _webSocket!.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
        cancelOnError: false,
      );

      _reconnectAttempts = 0;
    } catch (e) {
      _logError('WebSocket connection failed: $e');
      _isConnected = false;
      await _handleReconnect();
      rethrow;
    }
  }

  Future<void> _closeWebSocket() async {
    if (_webSocket != null) {
      try {
        _webSocket!.add(jsonEncode({'type': 'CloseStream'}));
        await Future.delayed(const Duration(milliseconds: 100));
        await _webSocket!.close(WebSocketStatus.normalClosure);
      } catch (e) {
        _logError('Error closing WebSocket: $e');
      }
      _webSocket = null;
      _isConnected = false;
    }
  }

  // ==================== AUDIO STREAMING ====================

  Future<void> _startAudioStream() async {
    if (_isDisposed || !_isRecorderInitialized) return;

    try {
      _recordingDataController = StreamController<Uint8List>();

      await _recorder.startRecorder(
        toStream: _recordingDataController!.sink,
        codec: Codec.pcm16,
        sampleRate: _sampleRate,
        numChannels: _channels,
      );

      _audioStreamSubscription = _recordingDataController!.stream.listen(
        _handleAudioData,
        onError: (error) => _logError('Audio stream error: $error'),
        cancelOnError: false,
      );
    } catch (e) {
      _logError('Failed to start audio stream: $e');
      rethrow;
    }
  }

  Future<void> _stopAudioStream() async {
    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    await _recordingDataController?.close();
    _recordingDataController = null;

    try {
      if (_isRecorderInitialized && _recorder.isRecording) {
        await _recorder.stopRecorder();
      }
    } catch (e) {
      _logError('Error stopping recorder: $e');
    }
  }

  void _handleAudioData(Uint8List audioBuffer) {
    if (_isDisposed || _webSocket == null || !_isConnected) return;

    try {
      _webSocket!.add(audioBuffer);
    } catch (e) {
      _logError('Error sending audio: $e');
    }
  }

  // ==================== WEBSOCKET MESSAGE HANDLING ====================

  void _handleWebSocketMessage(dynamic message) {
    if (_isDisposed) return;

    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'Results':
          _handleTranscriptResults(data);
          break;
        case 'UtteranceEnd':
          _interimTranscript = '';
          notifyListeners();
          break;
        case 'Error':
          _handleError(data);
          break;
      }
    } catch (e) {
      _logError('Error handling message: $e');
    }
  }

  void _handleTranscriptResults(Map<String, dynamic> data) {
    try {
      final channel = data['channel'] as Map<String, dynamic>?;
      if (channel == null) return;

      final alternatives = channel['alternatives'] as List<dynamic>?;
      if (alternatives == null || alternatives.isEmpty) return;

      final firstAlternative = alternatives[0] as Map<String, dynamic>;
      final transcript = firstAlternative['transcript'] as String? ?? '';
      final isFinal = data['is_final'] as bool? ?? false;
      final speechFinal = data['speech_final'] as bool? ?? false;

      if (transcript.isEmpty) return;

      final words = firstAlternative['words'] as List<dynamic>?;
      if (words != null && words.isNotEmpty) {
        final lastWord = words.last as Map<String, dynamic>;
        _latestWord = lastWord['word'] as String? ?? '';
      }

      if (isFinal || speechFinal) {
        _wordCount += transcript.split(' ').length;
        if (_fullTranscript.isNotEmpty) {
          _fullTranscript += ' ';
        }
        _fullTranscript += transcript;
        _interimTranscript = '';
      } else {
        _interimTranscript = transcript;
      }

      notifyListeners();
    } catch (e) {
      _logError('Error parsing transcript: $e');
    }
  }

  void _handleError(Map<String, dynamic> data) {
    final errorMessage = data['message'] ?? data['error'] ?? 'Unknown error';
    _logError('Deepgram error: $errorMessage');
  }

  void _handleWebSocketError(dynamic error) {
    _logError('WebSocket error: $error');
    _isConnected = false;
    if (!_isDisposed) {
      _handleReconnect();
    }
  }

  void _handleWebSocketDone() {
    _isConnected = false;
    if (!_isDisposed && _state == TranscriptionState.recording) {
      _handleReconnect();
    }
  }

  // ==================== RECONNECTION LOGIC ====================

  Future<void> _handleReconnect() async {
    if (_isDisposed) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logError('Max reconnection attempts reached');
      _setState(TranscriptionState.error);
      return;
    }

    _reconnectAttempts++;

    _reconnectTimer = Timer(
      Duration(milliseconds: _reconnectDelayMs),
      () async {
        try {
          await _closeWebSocket();
          await _connectWebSocket();
        } catch (e) {
          _logError('Reconnection failed: $e');
          await _handleReconnect();
        }
      },
    );
  }

  // ==================== KEEP-ALIVE ====================

  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(
      Duration(milliseconds: _keepAliveIntervalMs),
      (_) {
        if (_webSocket != null && _isConnected && !_isDisposed) {
          try {
            _webSocket!.add(jsonEncode({'type': 'KeepAlive'}));
          } catch (e) {
            _logError('Keep-alive failed: $e');
          }
        }
      },
    );
  }

  // ==================== STATE MANAGEMENT ====================

  void _setState(TranscriptionState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void _resetState() {
    _isDisposed = false;
    _isConnected = false;
    _fullTranscript = '';
    _interimTranscript = '';
    _latestWord = '';
    _wordCount = 0;
    _reconnectAttempts = 0;
  }

  Future<void> _cleanup() async {
    await _stopAudioStream();
    await _closeWebSocket();
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // ==================== LOGGING ====================

  void _logError(String message) {
    if (kDebugMode) {
      print('DeepgramTranscriber: $message');
    }
  }

  // ==================== DISPOSE ====================

  @override
  void dispose() {
    _isDisposed = true;
    _cleanup();

    if (_isRecorderInitialized) {
      _recorder.closeRecorder();
      _isRecorderInitialized = false;
    }

    super.dispose();
  }
}
