import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum ListeningState {
  idle,
  initializing,
  listening,
  pausing,
  processing,
  error,
  cooldown,
}

class RobustSpeechManager extends ChangeNotifier {
  // Core components
  late stt.SpeechToText _speech;

  // State management
  ListeningState _state = ListeningState.idle;
  String _fullTranscript = '';
  String _currentSegment = '';
  String _lastFinalizedSegment = '';

  // Smart timing configuration
  static const int SAFE_CHUNK_DURATION = 20; // Well under 30s limit
  static const int PAUSE_DURATION_MS = 300; // Time between chunks
  static const int ERROR_COOLDOWN_MS = 1000; // After errors
  static const int CASCADE_PREVENTION_MS = 2000; // When detecting cascades

  // Error prevention with exponential backoff
  int _consecutiveErrors = 0;
  int _successfulChunks = 0;
  final Queue<DateTime> _errorTimestamps = Queue<DateTime>();
  static const int ERROR_WINDOW_SIZE = 5;
  static const int ERROR_WINDOW_SECONDS = 10;

  // Restart management
  Timer? _chunkTimer;
  Timer? _cooldownTimer;
  DateTime? _lastRestartTime;
  bool _isDisposed = false;

  // Performance optimization
  bool _hasPartialResult = false;
  DateTime? _lastSpeechTime;
  static const int NO_SPEECH_TIMEOUT_MS = 3000;

  // Debug info
  final List<String> _debugLog = [];

  RobustSpeechManager() {
    _speech = stt.SpeechToText();
  }

  // Initialize with comprehensive error handling
  Future<bool> initialize() async {
    _setState(ListeningState.initializing);
    _log('Initializing speech recognition...');

    // Test permission status first
    final hasPermission = await _speech.hasPermission;
    _log('Permission status before initialize: $hasPermission');

    try {
      // Let speech_to_text handle permission requests during initialize()
      _log('Calling speech_to_text initialize...');
      final available = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: false,
        finalTimeout: Duration(seconds: 30),
      );

      if (available) {
        _log('Speech recognition initialized successfully');
        _setState(ListeningState.idle);
        return true;
      } else {
        _log('Speech recognition not available');
        _setState(ListeningState.error);
        return false;
      }
    } catch (e) {
      _log('Initialization failed: $e');
      _setState(ListeningState.error);
      return false;
    }
  }

  // Start continuous listening with all safeguards
  Future<void> startContinuousListening() async {
    if (_state == ListeningState.listening) {
      _log('Already listening, ignoring start request');
      return;
    }

    _log('Starting continuous listening...');
    _resetState();
    await _startNextChunk();
  }

  // Core listening logic with proactive management
  Future<void> _startNextChunk() async {
    if (_isDisposed) return;

    // Check if we're in cascade prevention mode
    if (_isInCascadeCondition()) {
      _log('Cascade condition detected, entering cooldown');
      _enterCooldown(CASCADE_PREVENTION_MS);
      return;
    }

    // Check if we need error cooldown
    if (_consecutiveErrors > 2) {
      final cooldownMs = ERROR_COOLDOWN_MS * _consecutiveErrors;
      _log('Multiple errors detected, cooldown for ${cooldownMs}ms');
      _enterCooldown(cooldownMs);
      return;
    }

    _setState(ListeningState.listening);
    _hasPartialResult = false;
    _lastSpeechTime = DateTime.now();

    try {
      // Cancel any existing timers
      _chunkTimer?.cancel();

      // Set up proactive chunk timer
      _chunkTimer = Timer(Duration(seconds: SAFE_CHUNK_DURATION), () {
        _log('Chunk timer fired, saving progress');
        _handleChunkComplete();
      });

      // Start listening with balanced settings for both direct speech and speaker audio
      await _speech.listen(
        onResult: _handleResult,
        listenFor: Duration(seconds: SAFE_CHUNK_DURATION + 2),
        pauseFor: Duration(seconds: 2), // Balanced pause duration
        partialResults: true,
        onDevice: false, // Cloud processing for better accuracy
        listenMode: stt.ListenMode.dictation, // More flexible than confirmation
        cancelOnError: false,
      );

      _lastRestartTime = DateTime.now();
      _log('Started listening chunk $_successfulChunks');
    } catch (e) {
      _log('Failed to start listening: $e');
      _handleListenError();
    }
  }

  // Handle speech results with state tracking
  void _handleResult(result) {
    if (_isDisposed || _state != ListeningState.listening) return;

    // Reset error count on successful result
    if (result.recognizedWords.isNotEmpty) {
      _consecutiveErrors = 0;
      _hasPartialResult = true;
      _lastSpeechTime = DateTime.now();
    }

    // Update current segment
    _currentSegment = result.recognizedWords;

    // Handle finalized results
    if (result.finalResult && result.recognizedWords.isNotEmpty) {
      _log('Final result: "${result.recognizedWords}"');

      // Only append if different from last finalized segment
      if (result.recognizedWords != _lastFinalizedSegment) {
        _fullTranscript +=
            (_fullTranscript.isEmpty ? '' : ' ') + result.recognizedWords;
        _lastFinalizedSegment = result.recognizedWords;
        _currentSegment = '';
        _successfulChunks++;
      }
    }

    notifyListeners();
  }

  // Status handler with intelligent decision making
  void _handleStatus(String status) {
    _log('Status: $status');

    if (status == 'done' && _state == ListeningState.listening) {
      // Natural completion - proceed with next chunk
      _handleChunkComplete();
    } else if (status == 'notListening' && _state == ListeningState.listening) {
      // Treat as natural completion instead of error for better stability
      _log('Speech stopped naturally, proceeding with chunk completion');
      _handleChunkComplete();
    }
  }

  // Error handler with cascade prevention
  void _handleError(error) {
    _log('Error: ${error.errorMsg} (permanent: ${error.permanent})');

    // Track error timing
    _errorTimestamps.add(DateTime.now());
    _cleanErrorTimestamps();

    // Handle based on error type
    switch (error.errorMsg) {
      case 'error_speech_timeout':
      case 'error_no_match':
        // These are expected - just restart
        if (_state == ListeningState.listening) {
          _handleChunkComplete();
        }
        break;

      case 'error_busy':
      case 'error_audio':
        // System busy - need longer cooldown
        _consecutiveErrors++;
        _enterCooldown(ERROR_COOLDOWN_MS * 2);
        break;

      default:
        // Other errors - use standard error handling
        _handleListenError();
        break;
    }
  }

  // Complete current chunk and prepare for next
  void _handleChunkComplete() {
    if (_state != ListeningState.listening) return;

    _chunkTimer?.cancel();
    _setState(ListeningState.processing);

    // Save any pending partial results
    if (_currentSegment.isNotEmpty &&
        _currentSegment != _lastFinalizedSegment) {
      _log('Saving partial result: "$_currentSegment"');
      _fullTranscript += (_fullTranscript.isEmpty ? '' : ' ') + _currentSegment;
      _lastFinalizedSegment = _currentSegment;
      _currentSegment = '';
    }

    // Stop current session
    _speech.stop();

    // Schedule next chunk with pause
    _setState(ListeningState.pausing);
    Timer(Duration(milliseconds: PAUSE_DURATION_MS), () {
      if (!_isDisposed &&
          (_state == ListeningState.pausing ||
              _state == ListeningState.processing)) {
        _startNextChunk();
      }
    });
  }

  // Handle errors with progressive backoff
  void _handleListenError() {
    _consecutiveErrors++;
    _chunkTimer?.cancel();

    if (_consecutiveErrors > 5) {
      _log('Too many consecutive errors, stopping');
      stopListening();
      return;
    }

    // Progressive backoff
    final backoffMs = ERROR_COOLDOWN_MS * _consecutiveErrors;
    _enterCooldown(backoffMs);
  }

  // Enter cooldown state with timer
  void _enterCooldown(int durationMs) {
    _setState(ListeningState.cooldown);
    _cooldownTimer?.cancel();

    _cooldownTimer = Timer(Duration(milliseconds: durationMs), () {
      if (!_isDisposed && _state == ListeningState.cooldown) {
        _log('Cooldown complete, resuming');
        _startNextChunk();
      }
    });
  }

  // Check for cascade conditions
  bool _isInCascadeCondition() {
    _cleanErrorTimestamps();

    // Too many errors in short time
    if (_errorTimestamps.length >= ERROR_WINDOW_SIZE) {
      _log('Cascade condition: ${_errorTimestamps.length} errors in window');
      return true;
    }

    // Restarting too quickly
    if (_lastRestartTime != null) {
      final timeSinceRestart = DateTime.now()
          .difference(_lastRestartTime!)
          .inMilliseconds;
      if (timeSinceRestart < 500) {
        _log('Cascade condition: restart too soon (${timeSinceRestart}ms)');
        return true;
      }
    }

    return false;
  }

  // Clean old error timestamps
  void _cleanErrorTimestamps() {
    final cutoff = DateTime.now().subtract(
      Duration(seconds: ERROR_WINDOW_SECONDS),
    );
    while (_errorTimestamps.isNotEmpty &&
        _errorTimestamps.first.isBefore(cutoff)) {
      _errorTimestamps.removeFirst();
    }
  }

  // Stop listening gracefully
  Future<void> stopListening() async {
    _log('Stopping continuous listening...');
    _isDisposed = true;

    // Cancel all timers
    _chunkTimer?.cancel();
    _cooldownTimer?.cancel();

    // Stop speech recognition
    if (_speech.isListening) {
      await _speech.stop();
    }

    // Save any pending results
    if (_currentSegment.isNotEmpty &&
        _currentSegment != _lastFinalizedSegment) {
      _fullTranscript += (_fullTranscript.isEmpty ? '' : ' ') + _currentSegment;
      _currentSegment = '';
    }

    _setState(ListeningState.idle);
    _log('Stopped. Total chunks: $_successfulChunks');
  }

  // Reset state for fresh start
  void _resetState() {
    _isDisposed = false;
    _fullTranscript = '';
    _currentSegment = '';
    _lastFinalizedSegment = '';
    _consecutiveErrors = 0;
    _successfulChunks = 0;
    _errorTimestamps.clear();
    _debugLog.clear();
    _hasPartialResult = false;
    _lastSpeechTime = null;
  }

  // State management
  void _setState(ListeningState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  // Debug logging
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1];
    final logMessage = '[$timestamp] $message';
    print('SpeechManager: $logMessage');
    _debugLog.add(logMessage);
    if (_debugLog.length > 100) {
      _debugLog.removeAt(0);
    }
  }

  // Getters
  String get transcript =>
      _fullTranscript + (_currentSegment.isEmpty ? '' : ' $_currentSegment');

  String get fullTranscript => _fullTranscript;

  String get currentSegment => _currentSegment;

  ListeningState get state => _state;

  bool get isListening => _state == ListeningState.listening;

  int get errorCount => _consecutiveErrors;

  int get chunkCount => _successfulChunks;

  List<String> get debugLog => List.unmodifiable(_debugLog);

  @override
  void dispose() {
    _isDisposed = true;
    _chunkTimer?.cancel();
    _cooldownTimer?.cancel();
    _speech.stop();
    super.dispose();
  }
}
