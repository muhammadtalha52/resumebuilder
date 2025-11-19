import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:skillresy/utils/secure_keys.dart';

import 'transcriber_interface.dart';
import 'transcription_config.dart';

/// Real-time WebSocket transcription implementation using flutter_sound
///
/// Streams raw PCM16 audio continuously via WebSocket to OpenAI Realtime API
/// and receives partial transcription updates in real-time.
///
/// Uses flutter_sound instead of record package for true PCM16 streaming support.
class RealtimeAudioTranscriber extends AudioTranscriber {
  // WebSocket connection
  WebSocket? _webSocket;
  String? _sessionId;

  // Audio recording with flutter_sound
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  StreamController<Uint8List>? _recordingDataController;
  bool _isRecorderInitialized = false;

  // State management
  TranscriptionState _state = TranscriptionState.idle;
  String _fullTranscript = '';
  String _latestSegment = '';
  String _currentDelta = ''; // Accumulates partial text within current segment

  // Typewriter effect for transcript display
  Timer? _typewriterTimer;
  String _typewriterDisplayed = ''; // What's currently displayed
  String _typewriterTarget = ''; // Target text to reach
  static const int _typewriterCharsPerTick = 3; // Characters to reveal per tick
  static const int _typewriterIntervalMs = 25; // Milliseconds between ticks

  // Timers and control
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer?
  _commitTimer; // Timer to force commits every 3 seconds during continuous speech
  bool _isDisposed = false;
  int _reconnectAttempts = 0;
  int _segmentCount = 0;
  DateTime? _lastCommitTime; // Track when we last committed audio

  // Help request cutoff
  int? _helpRequestCutoff;
  bool _ignoreNewAudio = false; // Flag to stop sending audio after cutoff

  // Debug info
  final List<String> _debugLog = [];

  // Configuration from TranscriptionConfig
  late final int _sampleRate;
  late final int _audioBufferMs;
  late final String _model;
  late final double _vadThreshold;
  late final int _silenceDurationMs;
  late final int _prefixPaddingMs;
  late final String _noiseReduction;
  late final int _maxReconnectAttempts;
  late final int _reconnectDelayMs;
  late final int _pingIntervalMs;

  RealtimeAudioTranscriber() {
    // Load configuration
    final config = TranscriptionConfig.realtimeConfig;
    _sampleRate = config['sampleRate'] as int;
    _audioBufferMs = config['audioBufferMs'] as int;
    _model = config['model'] as String;
    _vadThreshold = (config['vadThreshold'] as num).toDouble();
    _silenceDurationMs = config['silenceDurationMs'] as int;
    _prefixPaddingMs = config['prefixPaddingMs'] as int;
    _noiseReduction = config['noiseReduction'] as String;
    _maxReconnectAttempts = config['maxReconnectAttempts'] as int;
    _reconnectDelayMs = config['reconnectDelayMs'] as int;
    _pingIntervalMs = config['pingIntervalMs'] as int;
  }

  // ==================== INTERFACE GETTERS ====================

  @override
  TranscriptionState get state => _state;

  @override
  String get transcript =>
      _typewriterDisplayed.isEmpty ? _fullTranscript : _typewriterDisplayed;

  @override
  String get latestSegment => _latestSegment;

  @override
  bool get isRecording => _state == TranscriptionState.recording;

  @override
  int get chunkCount => _segmentCount;

  @override
  int get pendingChunks => 0; // Real-time has no pending chunks

  // ==================== INITIALIZATION ====================

  @override
  Future<bool> initialize() async {
    _setState(TranscriptionState.initializing);

    try {
      // Initialize flutter_sound recorder
      await _recorder.openRecorder();
      _isRecorderInitialized = true;

      _setState(TranscriptionState.idle);
      _log('✅ Initialization complete (flutter_sound)');
      return true;
    } catch (e) {
      _log('❌ Initialization error: $e');
      _setState(TranscriptionState.error);
      return false;
    }
  }

  // ==================== RECORDING CONTROL ====================

  @override
  Future<void> startRecording() async {
    if (_state == TranscriptionState.recording) {
      _log('⚠️ Already recording, ignoring start request');
      return;
    }

    _log('🎤 RECORDING START - Realtime WebSocket mode (flutter_sound)');
    _resetState();
    _setState(TranscriptionState.recording);

    try {
      // 1. Connect to WebSocket
      await _connectWebSocket();

      // 2. Start transcription session
      await _startTranscriptionSession();

      // 3. Start audio streaming
      await _startAudioStream();

      // 4. Start ping timer to keep connection alive
      _startPingTimer();

      _log('✅ Recording started successfully');
    } catch (e) {
      _log('❌ Failed to start recording: $e');
      _setState(TranscriptionState.error);
      await _cleanup();
    }
  }

  @override
  Future<void> stopRecording() async {
    _log('🛑 STOP RECORDING - Closing WebSocket and audio stream');

    _isDisposed = true;

    // Stop timers
    _pingTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopCommitTimer();

    // Stop audio stream
    await _stopAudioStream();

    // Send final commit if session active
    if (_webSocket != null && _sessionId != null) {
      try {
        _sendMessage({'type': 'input_audio_buffer.commit'});
      } catch (e) {
        _log('⚠️ Error committing final audio: $e');
      }
    }

    // Close WebSocket
    await _closeWebSocket();

    _setState(TranscriptionState.stopped);
    _log('✅ Recording stopped');
  }

  // ==================== WEBSOCKET CONNECTION ====================

  Future<void> _connectWebSocket() async {
    try {
      _log('📡 Connecting to WebSocket...');

      final apiKey = await SecureKeys.getOpenAiKey();
      final uri = Uri.parse(
        'wss://api.openai.com/v1/realtime?intent=transcription',
      );

      _webSocket = await WebSocket.connect(
        uri.toString(),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'OpenAI-Beta': 'realtime=v1',
        },
      ).timeout(Duration(seconds: 10));

      _log('✅ WebSocket connected');

      // Listen to incoming messages
      _webSocket!.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
        cancelOnError: false,
      );

      _reconnectAttempts = 0; // Reset on successful connection
    } catch (e) {
      _log('❌ WebSocket connection error: $e');
      await _handleReconnect();
      rethrow;
    }
  }

  Future<void> _closeWebSocket() async {
    if (_webSocket != null) {
      try {
        await _webSocket!.close(WebSocketStatus.normalClosure);
        _log('📡 WebSocket closed');
      } catch (e) {
        _log('⚠️ Error closing WebSocket: $e');
      }
      _webSocket = null;
      _sessionId = null;
    }
  }

  // ==================== TRANSCRIPTION SESSION ====================

  Future<void> _startTranscriptionSession() async {
    if (_webSocket == null) {
      throw Exception('WebSocket not connected');
    }

    _log('🎬 Starting transcription session...');

    // IMPORTANT: With intent=transcription, use transcription_session.update (NOT session.update)
    // Using session.update causes: "Passing a realtime session update event to a transcription session is not allowed"
    //
    // HYBRID APPROACH: Enable VAD + 3-second fallback timer
    // - VAD triggers commit on natural pauses
    // - Timer forces commit every 3s during continuous speech
    final sessionConfig = {
      'type': 'transcription_session.update',
      'session': {
        'input_audio_format': 'pcm16',
        'input_audio_transcription': {
          'model': 'gpt-4o-transcribe',
          'language': 'en',
        },
        'turn_detection': {
          'type': 'server_vad',
          'threshold': _vadThreshold,
          'prefix_padding_ms': _prefixPaddingMs,
          'silence_duration_ms': _silenceDurationMs,
        },
      },
    };

    _sendMessage(sessionConfig);
    _log(
      '✅ Sent transcription_session.update configuration (VAD enabled + 3s fallback)',
    );
  }

  // ==================== AUDIO STREAMING ====================

  Future<void> _startAudioStream() async {
    if (_isDisposed || !_isRecorderInitialized) return;

    _log(
      '🎙️ Starting audio stream (PCM16 @ ${_sampleRate}Hz) with flutter_sound...',
    );

    try {
      // Create StreamController for PCM16 audio buffers
      _recordingDataController = StreamController<Uint8List>();

      // Start streaming with PCM16 format
      await _recorder.startRecorder(
        toStream: _recordingDataController!.sink,
        codec: Codec.pcm16,
        sampleRate: _sampleRate,
        numChannels: 1, // Mono
      );

      // Listen to audio stream (receives Uint8List buffers directly)
      _audioStreamSubscription = _recordingDataController!.stream.listen(
        (Uint8List audioBuffer) {
          _handleAudioData(audioBuffer);
        },
        onError: (error) {
          _log('❌ Audio stream error: $error');
        },
        onDone: () {
          _log('🎙️ Audio stream ended');
        },
        cancelOnError: false,
      );

      _log('✅ Audio streaming started (flutter_sound PCM16)');
    } catch (e) {
      _log('❌ Failed to start audio stream: $e');
      rethrow;
    }
  }

  Future<void> _stopAudioStream() async {
    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    // Close stream controller
    await _recordingDataController?.close();
    _recordingDataController = null;

    try {
      if (_isRecorderInitialized && _recorder.isRecording) {
        await _recorder.stopRecorder();
      }
    } catch (e) {
      _log('⚠️ Error stopping recorder: $e');
    }

    _log('🎙️ Audio stream stopped');
  }

  void _handleAudioData(Uint8List audioBuffer) {
    if (_isDisposed || _webSocket == null || _ignoreNewAudio) {
      return;
    }

    try {
      // flutter_sound gives us raw PCM16 data - no header stripping needed!
      // Convert PCM16 bytes to base64
      final base64Audio = base64Encode(audioBuffer);

      // Send to WebSocket
      _sendMessage({'type': 'input_audio_buffer.append', 'audio': base64Audio});
    } catch (e) {
      _log('⚠️ Error sending audio data: $e');
    }
  }

  // ==================== WEBSOCKET MESSAGE HANDLING ====================

  void _sendMessage(Map<String, dynamic> message) {
    if (_webSocket == null || _isDisposed) return;

    try {
      final jsonMessage = jsonEncode(message);
      _webSocket!.add(jsonMessage);
    } catch (e) {
      _log('⚠️ Error sending message: $e');
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    if (_isDisposed) return;

    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final eventType = data['type'] as String?;

      switch (eventType) {
        case 'session.created':
          _sessionId = data['session']?['id'] as String?;
          _log('✅ Session created: $_sessionId');
          _log('📋 Full session data: ${jsonEncode(data)}');
          break;

        case 'session.updated':
          _log('✅ Session updated');
          break;

        case 'input_audio_buffer.committed':
          _log('📝 Audio buffer committed');
          _lastCommitTime = DateTime.now();
          // Don't stop timer here - let it continue for next 3s interval
          break;

        case 'input_audio_buffer.speech_started':
          _log('🗣️ Speech detected');
          _startCommitTimer(); // Start 3-second fallback timer
          break;

        case 'input_audio_buffer.speech_stopped':
          _log('🔇 Speech stopped');
          _stopCommitTimer(); // Stop timer when speech actually ends
          break;

        case 'conversation.item.created':
          _log('📨 Received event: conversation.item.created');
          _log('📋 Full item data: ${jsonEncode(data)}');
          break;

        case 'conversation.item.input_audio_transcription.delta':
          _handleTranscriptDelta(data);
          break;

        case 'conversation.item.input_audio_transcription.completed':
          _handleTranscriptCompleted(data);
          break;

        case 'error':
          _handleError(data);
          break;

        default:
          _log('📨 Received event: $eventType');
          _log('📋 Full data: ${jsonEncode(data)}');
      }
    } catch (e) {
      _log('⚠️ Error handling WebSocket message: $e');
    }
  }

  void _handleTranscriptDelta(Map<String, dynamic> data) {
    // Partial transcription update (word by word)
    final delta = data['delta'] as String? ?? '';

    if (delta.isNotEmpty) {
      _currentDelta += delta;
      _latestSegment = _currentDelta;

      notifyListeners();
      _log('💬 Delta: "$delta" (accumulated: "$_currentDelta")');
    }
  }

  void _handleTranscriptCompleted(Map<String, dynamic> data) {
    // Finalized segment
    final transcript = data['transcript'] as String? ?? '';

    if (transcript.isNotEmpty) {
      _segmentCount++;

      // Add to full transcript
      if (_fullTranscript.isNotEmpty) {
        _fullTranscript += ' ';
      }
      _fullTranscript += transcript;

      // Update latest segment
      _latestSegment = transcript;

      // Reset current delta
      _currentDelta = '';

      // Start typewriter effect for new text
      _startTypewriterEffect();

      _log('✅ Segment #$_segmentCount completed: "$transcript"');
    }
  }

  // ==================== TYPEWRITER EFFECT ====================

  void _startTypewriterEffect() {
    // Set the target to the full transcript
    _typewriterTarget = _fullTranscript;

    // Stop any existing timer
    _typewriterTimer?.cancel();

    // Start typewriter timer
    _typewriterTimer = Timer.periodic(
      Duration(milliseconds: _typewriterIntervalMs),
      (_) {
        if (_typewriterDisplayed.length < _typewriterTarget.length) {
          // Reveal more characters
          final remaining =
              _typewriterTarget.length - _typewriterDisplayed.length;
          final charsToAdd = remaining < _typewriterCharsPerTick
              ? remaining
              : _typewriterCharsPerTick;

          _typewriterDisplayed = _typewriterTarget.substring(
            0,
            _typewriterDisplayed.length + charsToAdd,
          );

          notifyListeners();
        } else {
          // Finished typewriter effect
          _typewriterTimer?.cancel();
          _typewriterTimer = null;
        }
      },
    );
  }

  void _stopTypewriterEffect() {
    _typewriterTimer?.cancel();
    _typewriterTimer = null;
    // Instantly show full transcript
    _typewriterDisplayed = _fullTranscript;
    _typewriterTarget = _fullTranscript;
  }

  void _handleError(Map<String, dynamic> data) {
    final error = data['error'] as Map<String, dynamic>?;
    final message = error?['message'] ?? 'Unknown error';
    _log('❌ WebSocket error: $message');
  }

  void _handleWebSocketError(dynamic error) {
    _log('❌ WebSocket error: $error');
    if (!_isDisposed) {
      _handleReconnect();
    }
  }

  void _handleWebSocketDone() {
    _log('📡 WebSocket connection closed');
    if (!_isDisposed && _state == TranscriptionState.recording) {
      _handleReconnect();
    }
  }

  // ==================== RECONNECTION LOGIC ====================

  Future<void> _handleReconnect() async {
    if (_isDisposed) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log('❌ Max reconnection attempts reached');
      _setState(TranscriptionState.error);
      return;
    }

    _reconnectAttempts++;
    _log(
      '🔄 Attempting reconnection ($_reconnectAttempts/$_maxReconnectAttempts)...',
    );

    _reconnectTimer = Timer(
      Duration(milliseconds: _reconnectDelayMs),
      () async {
        try {
          await _closeWebSocket();
          await _connectWebSocket();
          await _startTranscriptionSession();
          _log('✅ Reconnection successful');
        } catch (e) {
          _log('❌ Reconnection failed: $e');
          await _handleReconnect();
        }
      },
    );
  }

  // ==================== PING TIMER ====================

  void _startPingTimer() {
    // NOTE: WebSocket protocol handles keep-alive at the transport layer.
    // Sending raw 'ping' strings causes "Invalid event: failed to parse JSON"
    // The Realtime API doesn't require application-level pings.
    // Disabling to prevent JSON parsing errors.

    // If keep-alive is needed, periodically commit audio buffer instead:
    // _pingTimer = Timer.periodic(Duration(milliseconds: _pingIntervalMs), (_) {
    //   if (_webSocket != null && !_isDisposed) {
    //     _sendMessage({'type': 'input_audio_buffer.commit'});
    //   }
    // });
  }

  // ==================== COMMIT TIMER (3-SECOND FALLBACK) ====================

  void _startCommitTimer() {
    // Cancel any existing timer first
    _stopCommitTimer();

    // Start 3-second timer to force commit if VAD doesn't trigger
    _commitTimer = Timer(Duration(seconds: 3), () {
      if (_webSocket != null && !_isDisposed && !_ignoreNewAudio) {
        _log('⏰ 3s timeout - forcing commit during continuous speech');
        _sendMessage({'type': 'input_audio_buffer.commit'});
        // Restart timer for next 3 seconds if still speaking
        _startCommitTimer();
      }
    });
  }

  void _stopCommitTimer() {
    _commitTimer?.cancel();
    _commitTimer = null;
  }

  // ==================== HELP REQUEST METHODS ====================

  @override
  void setHelpRequestCutoff() {
    _helpRequestCutoff = _segmentCount;
    _ignoreNewAudio = true; // Stop sending new audio
    _log(
      '🔒 HELP CUTOFF SET: Segment $_helpRequestCutoff (audio streaming paused)',
    );
  }

  @override
  void clearHelpRequestCutoff() {
    if (_helpRequestCutoff != null) {
      _log('🔓 HELP CUTOFF CLEARED: Resuming audio streaming');
      _helpRequestCutoff = null;
      _ignoreNewAudio = false;
    }
  }

  @override
  Future<void> waitForChunksUpToCutoff({int maxWaitMs = 5000}) async {
    // For realtime API, there are no pending chunks to wait for
    // The transcript is already up-to-date when cutoff is set
    _log('✅ Realtime API - transcript already current (no waiting needed)');
    return;
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
    _fullTranscript = '';
    _latestSegment = '';
    _currentDelta = '';
    _segmentCount = 0;
    _reconnectAttempts = 0;
    _helpRequestCutoff = null;
    _ignoreNewAudio = false;
    _debugLog.clear();

    // Reset typewriter effect
    _typewriterTimer?.cancel();
    _typewriterTimer = null;
    _typewriterDisplayed = '';
    _typewriterTarget = '';
  }

  Future<void> _cleanup() async {
    await _stopAudioStream();
    await _closeWebSocket();
    _pingTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopCommitTimer();

    // Stop typewriter effect
    _typewriterTimer?.cancel();
    _typewriterTimer = null;
  }

  // ==================== DEBUG LOGGING ====================

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1];
    final logMessage = '[$timestamp] $message';
    if (kDebugMode) {
      print('RealtimeAudioTranscriber: $logMessage');
    }
    _debugLog.add(logMessage);
    if (_debugLog.length > 100) {
      _debugLog.removeAt(0);
    }
  }

  String get debugInfo {
    return '''
State: $_state
Session ID: $_sessionId
Segments: $_segmentCount
Reconnect attempts: $_reconnectAttempts
Transcript length: ${_fullTranscript.length} chars
Latest segment: "$_latestSegment"
''';
  }

  List<String> get debugLog => List.unmodifiable(_debugLog);

  // ==================== DISPOSE ====================

  @override
  void dispose() {
    _log('🗑️ DISPOSE called - cleaning up realtime transcriber');
    _isDisposed = true;
    _cleanup();

    // Close flutter_sound recorder
    if (_isRecorderInitialized) {
      _recorder.closeRecorder();
      _isRecorderInitialized = false;
    }

    super.dispose();
    _log('🗑️ DISPOSE complete');
  }
}
