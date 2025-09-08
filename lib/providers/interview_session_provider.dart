import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

enum InterviewSessionState {
  idle,
  listening,
  paused,
  showingHelp,
  recording, // User is speaking into mic
  processing, // AI is processing the recorded audio
}

class InterviewQuestion {
  final String text;
  final DateTime timestamp;
  final String? aiResponse;

  InterviewQuestion({
    required this.text,
    required this.timestamp,
    this.aiResponse,
  });

  InterviewQuestion copyWith({
    String? text,
    DateTime? timestamp,
    String? aiResponse,
  }) {
    return InterviewQuestion(
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      aiResponse: aiResponse ?? this.aiResponse,
    );
  }
}

class InterviewSessionData {
  final InterviewSessionState state;
  final Duration sessionDuration;
  final List<InterviewQuestion> questions; // Keep for AI responses later
  final String fullTranscript; // Single growing transcript
  final String? currentTranscription; // Live partial transcription
  final bool isListening;
  final String? error;

  InterviewSessionData({
    this.state = InterviewSessionState.idle,
    this.sessionDuration = Duration.zero,
    this.questions = const [],
    this.fullTranscript = '',
    this.currentTranscription,
    this.isListening = false,
    this.error,
  });

  InterviewSessionData copyWith({
    InterviewSessionState? state,
    Duration? sessionDuration,
    List<InterviewQuestion>? questions,
    String? fullTranscript,
    String? currentTranscription,
    bool? isListening,
    String? error,
  }) {
    return InterviewSessionData(
      state: state ?? this.state,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      questions: questions ?? this.questions,
      fullTranscript: fullTranscript ?? this.fullTranscript,
      currentTranscription: currentTranscription,
      isListening: isListening ?? this.isListening,
      error: error,
    );
  }
}

class InterviewSessionNotifier extends StateNotifier<InterviewSessionData> {
  Timer? _sessionTimer;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _shouldKeepListening = false; // Flag to control continuous listening
  bool _isInitializing = false; // Prevent multiple initializations
  String _pendingWords = ''; // Store partial results during restart

  InterviewSessionNotifier() : super(InterviewSessionData()) {
    _initSpeech();
  }

  // Initialize speech to text with status and error listeners
  Future<void> _initSpeech() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      print('Initializing speech recognition...');
      _speechEnabled = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: true, // Enable debug logging for iOS issues
      );
      print('Speech recognition initialized: $_speechEnabled');

      if (!_speechEnabled) {
        // Try to get more info about why it failed
        final hasPermission = await _speechToText.hasPermission;
        print('Has speech permission: $hasPermission');
      }
    } catch (e) {
      print('Speech initialization error: $e');
      _speechEnabled = false;
      state = state.copyWith(
        error: 'Speech initialization failed: ${e.toString()}',
      );
    } finally {
      _isInitializing = false;
    }
  }

  // Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    print('Speech status: $status');

    // If speech recognition stopped and we should keep listening, restart it
    if (status == 'done' && _shouldKeepListening && _speechEnabled) {
      // Save any pending partial results before restart
      if (_pendingWords.isNotEmpty) {
        addToFullTranscript(_pendingWords);
        _pendingWords = '';
      }

      // Restart listening after brief delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_shouldKeepListening) {
          _startListening();
        }
      });
    }
  }

  // Handle speech recognition errors
  void _onSpeechError(dynamic error) {
    print('Speech error: $error');

    // Don't show transient errors to user, just try to recover
    if (_shouldKeepListening && _speechEnabled) {
      // Try to reinitialize and restart after error
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (_shouldKeepListening) {
          await _initSpeech();
          if (_speechEnabled) {
            _startListening();
          }
        }
      });
    } else {
      // Show persistent errors to user
      state = state.copyWith(
        error: 'Speech recognition error: ${error.toString()}',
      );
    }
  }

  // Start interview session
  Future<void> startSession() async {
    print('StartSession called');
    try {
      // First check if speech recognition itself has permission (more reliable on iOS)
      print('Checking speech recognition capabilities...');
      final speechHasPermission = await _speechToText.hasPermission;
      print('Speech recognition hasPermission: $speechHasPermission');

      // Check microphone permission via permission_handler
      print('Checking microphone permission via permission_handler...');
      final micPermission = await Permission.microphone.status;
      print('Microphone permission status: $micPermission');

      // Also check speech recognition permission on iOS
      final speechPermission = await Permission.speech.status;
      print('Speech recognition permission status: $speechPermission');

      // If speech recognition says it doesn't have permission, try to get it
      if (!speechHasPermission) {
        print('Speech recognition reports no permission, requesting...');

        // Try to request permissions via speech_to_text first (more reliable)
        final speechInitResult = await _speechToText.initialize();
        print(
          'Speech initialization with permission request result: $speechInitResult',
        );

        if (!speechInitResult) {
          print('Speech initialization failed, showing permission dialog');
          state = state.copyWith(
            error: 'PERMISSION_DENIED_DIALOG', // Special error code for dialog
          );
          return;
        }

        _speechEnabled = speechInitResult;
      }

      // Double-check: if permission_handler still shows denied but speech works, continue anyway
      if (micPermission == PermissionStatus.permanentlyDenied &&
          !speechHasPermission) {
        print('Both permission checks failed, showing dialog');
        state = state.copyWith(
          error: 'PERMISSION_DENIED_DIALOG', // Special error code for dialog
        );
        return;
      }

      // If we get here and speechToText says it has permission, trust it over permission_handler
      if (speechHasPermission || _speechEnabled) {
        print(
          'Speech recognition has permission, proceeding with session start',
        );
      } else {
        // Fallback: try permission_handler approach
        if (micPermission != PermissionStatus.granted) {
          print('Requesting microphone permission via permission_handler...');
          final requestResult = await Permission.microphone.request();
          print('Microphone permission request result: $requestResult');

          if (requestResult != PermissionStatus.granted &&
              requestResult == PermissionStatus.permanentlyDenied) {
            state = state.copyWith(
              error:
                  'PERMISSION_DENIED_DIALOG', // Special error code for dialog
            );
            return;
          }
        }
      }

      // Ensure speech recognition is initialized before starting session
      if (!_speechEnabled) {
        print('Speech not enabled, initializing...');
        await _initSpeech();
        if (!_speechEnabled) {
          print('Failed to initialize speech recognition');
          state = state.copyWith(
            error: 'Speech recognition is not available on this device',
          );
          return;
        }
      }

      print('Starting session with all permissions granted');
      // Permission granted - proceed with starting session
      state = state.copyWith(
        state: InterviewSessionState.listening,
        isListening: true,
        error: null,
      );

      _startTimer();

      // No mock questions - real speech-to-text only
    } catch (e) {
      print('Error in startSession: $e');
      state = state.copyWith(error: 'Failed to start session: ${e.toString()}');
    }
  }

  // Pause session
  void pauseSession() {
    if (state.state == InterviewSessionState.listening) {
      state = state.copyWith(
        state: InterviewSessionState.paused,
        isListening: false,
      );
      _pauseTimer();
    }
  }

  // Resume session
  Future<void> resumeSession() async {
    if (state.state == InterviewSessionState.paused) {
      state = state.copyWith(
        state: InterviewSessionState.listening,
        isListening: true,
      );
      _resumeTimer();
    }
  }

  // Stop session
  void stopSession() {
    state = state.copyWith(
      state: InterviewSessionState.idle,
      isListening: false,
    );
    _stopTimer();
  }

  // Show help popup
  void showHelp() {
    if (state.state == InterviewSessionState.listening) {
      state = state.copyWith(state: InterviewSessionState.showingHelp);
    }
  }

  // Hide help popup
  void hideHelp() {
    if (state.state == InterviewSessionState.showingHelp) {
      state = state.copyWith(state: InterviewSessionState.listening);
    }
  }

  // Switch back to listening from any other state
  void backToListening() {
    state = state.copyWith(
      state: InterviewSessionState.listening,
      isListening: true,
    );
  }

  // Add transcribed question
  void addQuestion(String text) {
    final question = InterviewQuestion(text: text, timestamp: DateTime.now());

    final updatedQuestions = [...state.questions, question];
    state = state.copyWith(questions: updatedQuestions);
  }

  // Add AI response to a question
  void addAiResponse(int questionIndex, String response) {
    if (questionIndex < state.questions.length) {
      final updatedQuestions = [...state.questions];
      updatedQuestions[questionIndex] = updatedQuestions[questionIndex]
          .copyWith(aiResponse: response);
      state = state.copyWith(questions: updatedQuestions);
    }
  }

  // Update current transcription
  void updateTranscription(String transcription) {
    state = state.copyWith(currentTranscription: transcription);
  }

  // Add text to full transcript
  void addToFullTranscript(String text) {
    final currentTranscript = state.fullTranscript;
    final separator = currentTranscript.isEmpty ? '' : ' ';
    final newTranscript = currentTranscript + separator + text;

    state = state.copyWith(
      fullTranscript: newTranscript,
      currentTranscription: '', // Clear current since it's now saved
    );
  }

  // Toggle microphone ON/OFF
  Future<void> toggleMicrophone() async {
    print('ToggleMicrophone called, current state: ${state.state}');

    if (state.state == InterviewSessionState.recording) {
      // Turn OFF microphone - stop continuous listening
      _shouldKeepListening = false;
      await _stopListening();
    } else if (state.state == InterviewSessionState.listening ||
        state.state == InterviewSessionState.showingHelp) {
      // Turn ON microphone - start continuous listening
      _shouldKeepListening = true;
      await _startListening();
    }
  }

  // Start continuous listening with auto-restart capability
  Future<void> _startListening() async {
    // Don't start if already listening or if we shouldn't be listening
    if (_speechToText.isListening || !_shouldKeepListening) return;

    // No need to check permission here since we already checked in startSession()
    // Just ensure speech recognition is initialized
    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) {
        state = state.copyWith(error: 'Speech recognition not available');
        return;
      }
    }

    // Update state to recording
    state = state.copyWith(
      state: InterviewSessionState.recording,
      currentTranscription: '',
      error: null,
    );

    try {
      // Start listening with reasonable timeouts (not excessive)
      await _speechToText.listen(
        onResult: (result) {
          // Store partial results for potential restart
          _pendingWords = result.recognizedWords;

          // Update live transcription in real-time
          updateTranscription(result.recognizedWords);

          // If this is a final result, add to full transcript and clear pending
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            addToFullTranscript(result.recognizedWords);
            _pendingWords = ''; // Clear since it's now saved
          }
        },
        listenFor: const Duration(minutes: 5), // Reasonable timeout
        pauseFor: const Duration(seconds: 10), // Reasonable pause detection
        localeId: 'en_US',
        listenOptions: SpeechListenOptions(
          partialResults: true, // Show partial results for real-time effect
          cancelOnError: false, // Don't cancel on temporary errors
        ),
      );
    } catch (e) {
      // Handle any errors that occur during listening
      state = state.copyWith(
        error: 'Failed to start listening: ${e.toString()}',
      );
    }
  }

  // Stop listening
  Future<void> _stopListening() async {
    await _speechToText.stop();

    // Save any remaining current transcription to full transcript
    final currentTranscription = state.currentTranscription ?? '';
    if (currentTranscription.isNotEmpty) {
      addToFullTranscript(currentTranscription);
    }

    // Return to listening state
    state = state.copyWith(
      state: InterviewSessionState.listening,
      currentTranscription: null,
    );
  }

  // Clear error state (useful for dismissing dialogs)
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Legacy methods for compatibility (now just call toggle)
  Future<void> startRecording() => toggleMicrophone();

  Future<void> stopRecordingAndProcess() => toggleMicrophone();

  // Timer management
  void _startTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(
        sessionDuration: state.sessionDuration + const Duration(seconds: 1),
      );
    });
  }

  void _pauseTimer() {
    _sessionTimer?.cancel();
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _stopTimer() {
    _sessionTimer?.cancel();
    state = state.copyWith(sessionDuration: Duration.zero);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}

final interviewSessionProvider =
    StateNotifierProvider<InterviewSessionNotifier, InterviewSessionData>(
      (ref) => InterviewSessionNotifier(),
    );
