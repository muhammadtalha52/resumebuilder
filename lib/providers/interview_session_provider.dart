import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/interview_service.dart';
import '../models/interview_session_models.dart';
import '../models/conversation_models.dart';
import '../screens/interview/robust_speech_manager.dart';

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

  // NEW: Conversation-based approach
  final ConversationData conversation;

  // LEGACY: Keep for backward compatibility during transition
  final String fullTranscript; // Single growing transcript
  final String? currentTranscription; // Live partial transcription

  final bool isListening;
  final String? error;

  // API session metadata
  final String? sessionId; // From API response
  final bool isStartingSession; // Loading state for API call
  final String? sessionType;
  final String? role;
  final String? companyName;
  final String? jobDescription;
  final String? language;
  final String? resumeText;

  // Help functionality
  final bool isGettingHelp; // Loading state for help API call
  final String? helpResponse; // AI help response
  final DateTime? helpTimestamp; // When help was received

  InterviewSessionData({
    this.state = InterviewSessionState.idle,
    this.sessionDuration = Duration.zero,
    this.questions = const [],
    ConversationData? conversation,
    this.fullTranscript = '',
    this.currentTranscription,
    this.isListening = false,
    this.error,
    this.sessionId,
    this.isStartingSession = false,
    this.sessionType,
    this.role,
    this.companyName,
    this.jobDescription,
    this.language,
    this.resumeText,
    this.isGettingHelp = false,
    this.helpResponse,
    this.helpTimestamp,
  }) : conversation = conversation ?? ConversationData();

  InterviewSessionData copyWith({
    InterviewSessionState? state,
    Duration? sessionDuration,
    List<InterviewQuestion>? questions,
    ConversationData? conversation,
    String? fullTranscript,
    String? currentTranscription,
    bool? isListening,
    String? error,
    String? sessionId,
    bool? isStartingSession,
    String? sessionType,
    String? role,
    String? companyName,
    String? jobDescription,
    String? language,
    String? resumeText,
    bool? isGettingHelp,
    String? helpResponse,
    DateTime? helpTimestamp,
  }) {
    return InterviewSessionData(
      state: state ?? this.state,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      questions: questions ?? this.questions,
      conversation: conversation ?? this.conversation,
      fullTranscript: fullTranscript ?? this.fullTranscript,
      currentTranscription: currentTranscription,
      isListening: isListening ?? this.isListening,
      error: error,
      sessionId: sessionId ?? this.sessionId,
      isStartingSession: isStartingSession ?? this.isStartingSession,
      sessionType: sessionType ?? this.sessionType,
      role: role ?? this.role,
      companyName: companyName ?? this.companyName,
      jobDescription: jobDescription ?? this.jobDescription,
      language: language ?? this.language,
      resumeText: resumeText ?? this.resumeText,
      isGettingHelp: isGettingHelp ?? this.isGettingHelp,
      helpResponse: helpResponse ?? this.helpResponse,
      helpTimestamp: helpTimestamp ?? this.helpTimestamp,
    );
  }
}

class InterviewSessionNotifier extends StateNotifier<InterviewSessionData> {
  Timer? _sessionTimer;
  late RobustSpeechManager _speechManager;
  final InterviewService _interviewService = InterviewService();

  InterviewSessionNotifier() : super(InterviewSessionData()) {
    print('[INIT] InterviewSessionNotifier created with RobustSpeechManager');
    _speechManager = RobustSpeechManager();
    _speechManager.addListener(_onSpeechUpdate);
  }

  // Listen to speech manager updates and sync with provider state
  void _onSpeechUpdate() {
    state = state.copyWith(
      fullTranscript: _speechManager.fullTranscript,
      currentTranscription: _speechManager.currentSegment,
      isListening: _speechManager.isListening,
    );

    // Update conversation message with new transcript
    _updateCurrentConversationMessage(_speechManager.fullTranscript);
  }

  // Start interview session
  Future<void> startSession() async {
    print('StartSession called');

    // COMPLETE RESET - Clear everything from previous sessions
    print('[SESSION_RESET] Performing complete session reset');

    // Stop any ongoing listening with RobustSpeechManager
    await _speechManager.stopListening();

    // Reset the UI state but KEEP session metadata if it exists
    state = InterviewSessionData(
      sessionId: state.sessionId,
      sessionType: state.sessionType,
      role: state.role,
      companyName: state.companyName,
      jobDescription: state.jobDescription,
      language: state.language,
      resumeText: state.resumeText,
    ); // Reset but preserve API session data

    print(
      '[SESSION_RESET] All previous data cleared, keeping session metadata',
    );

    try {
      // Check microphone permission via permission_handler
      print('Checking microphone permission...');
      final micPermission = await Permission.microphone.status;
      print('Microphone permission status: $micPermission');

      // Also check speech recognition permission on iOS
      final speechPermission = await Permission.speech.status;
      print('Speech recognition permission status: $speechPermission');

      // Request permissions if needed
      if (micPermission != PermissionStatus.granted) {
        print('Requesting microphone permission...');
        final requestResult = await Permission.microphone.request();
        print('Microphone permission request result: $requestResult');

        if (requestResult != PermissionStatus.granted &&
            requestResult == PermissionStatus.permanentlyDenied) {
          state = state.copyWith(
            error: 'PERMISSION_DENIED_DIALOG', // Special error code for dialog
          );
          return;
        }
      }

      // Initialize RobustSpeechManager
      print('Initializing RobustSpeechManager...');
      final initialized = await _speechManager.initialize();
      if (!initialized) {
        print('Failed to initialize RobustSpeechManager');
        state = state.copyWith(
          error: 'Speech recognition is not available on this device',
        );
        return;
      }

      print('Starting session with all permissions granted');
      // Permission granted - proceed with starting session
      state = state.copyWith(
        state: InterviewSessionState.listening,
        isListening: true,
        error: null,
      );

      _startTimer();

      // AUTO-START: Begin continuous listening immediately
      print('[AUTO-START] Starting continuous listening automatically');
      _startNewConversationMessage();
      await _speechManager.startContinuousListening();
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
  Future<void> stopSession() async {
    print('[SESSION-STOP] Stopping session and cleaning up all data');

    // Stop continuous listening with RobustSpeechManager
    await _speechManager.stopListening();

    // Stop timer
    _stopTimer();

    // Clear all session data and reset to initial state
    state = InterviewSessionData(
      state: InterviewSessionState.idle,
      sessionDuration: Duration.zero,
      questions: const [],
      conversation: ConversationData(),
      fullTranscript: '',
      currentTranscription: null,
      isListening: false,
      error: null,
      sessionId: null,
      isStartingSession: false,
      sessionType: null,
      role: null,
      companyName: null,
      jobDescription: null,
      language: null,
      resumeText: null,
      helpResponse: null,
      helpTimestamp: null,
      isGettingHelp: false,
    );

    print('[SESSION-STOP] Session stopped, all data cleared');
  }

  // Show help popup

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
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] updateTranscription called');
    print('  - New transcription: "$transcription"');
    print('  - Previous transcription: "${state.currentTranscription}"');
    state = state.copyWith(currentTranscription: transcription);
  }

  // Add text to full transcript (legacy - kept for compatibility)
  void addToFullTranscript(String text) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] addToFullTranscript called');
    print('  - Text to add: "$text"');
    print('  - Current full transcript length: ${state.fullTranscript.length}');

    final currentTranscript = state.fullTranscript;
    final separator = currentTranscript.isEmpty ? '' : ' ';
    final newTranscript = currentTranscript + separator + text;

    print('  - New full transcript length: ${newTranscript.length}');
    print('  - Clearing current transcription');

    state = state.copyWith(
      fullTranscript: newTranscript,
      currentTranscription: '', // Clear current since it's now saved
    );

    // Also update the current conversation message if we're composing
    _updateCurrentConversationMessage(newTranscript);
  }

  // Add or update current conversation message
  void _updateCurrentConversationMessage(String text) {
    final conversation = state.conversation;

    // If there's a current user message being composed, update it
    if (conversation.currentUserId != null) {
      final messages = List<ConversationMessage>.from(conversation.messages);
      final index = messages.indexWhere(
        (msg) => msg.id == conversation.currentUserId,
      );

      if (index != -1) {
        // Update existing message content
        messages[index] = messages[index].copyWith(
          content: messages[index].content.isEmpty
              ? text
              : '${messages[index].content} $text',
          state: MessageState.composing,
        );

        state = state.copyWith(
          conversation: conversation.copyWith(messages: messages),
        );
      }
    }
  }

  // Start a new conversation message (called when recording starts)
  void _startNewConversationMessage() {
    print('[CONVERSATION] Starting new conversation message');

    final newMessage = ConversationMessage(
      type: MessageType.user,
      content: '',
      state: MessageState.composing,
    );

    final messages = List<ConversationMessage>.from(
      state.conversation.messages,
    );
    messages.add(newMessage);

    state = state.copyWith(
      conversation: state.conversation.copyWith(
        messages: messages,
        currentUserId: newMessage.id,
        isRecording: true,
      ),
    );

    print('[CONVERSATION] New message created with ID: ${newMessage.id}');
  }

  // Add Scout AI response as a new message and return its ID
  String _addScoutResponse(
    String response, [
    AssistantMessageType? assistantType,
  ]) {
    print(
      '[CONVERSATION] Adding Scout response (type: ${assistantType ?? AssistantMessageType.help})',
    );

    final scoutMessage = ConversationMessage(
      type: MessageType.assistant,
      content: response,
      state: MessageState.sent,
      assistantType: assistantType ?? AssistantMessageType.help,
    );

    final messages = List<ConversationMessage>.from(
      state.conversation.messages,
    );
    messages.add(scoutMessage);

    state = state.copyWith(
      conversation: state.conversation.copyWith(messages: messages),
    );

    print('[CONVERSATION] Scout response added with ID: ${scoutMessage.id}');
    return scoutMessage.id;
  }

  // Update existing Scout response by ID (for streaming)
  void _updateScoutResponse(String messageId, String newContent) {
    print('[CONVERSATION] Updating Scout response ID: $messageId');

    final conversation = state.conversation;
    final messages = List<ConversationMessage>.from(conversation.messages);
    final index = messages.indexWhere((msg) => msg.id == messageId);

    if (index != -1) {
      messages[index] = messages[index].copyWith(content: newContent);

      state = state.copyWith(
        conversation: conversation.copyWith(messages: messages),
      );

      print(
        '[CONVERSATION] Scout response updated. Length: ${newContent.length} chars',
      );
    } else {
      print('[CONVERSATION] Warning: Message ID not found: $messageId');
    }
  }

  // Public method to get follow-up questions
  void getFollowUpQuestions() async {
    if (state.sessionId == null) {
      print('[FOLLOW-UP] No active session');
      return;
    }

    try {
      // Set loading state
      state = state.copyWith(isGettingHelp: true);

      // Create follow-up request
      final request = SessionFollowUpRequest(
        sessionId: state.sessionId!,
        transcript: state.fullTranscript.trim(),
      );

      print('[FOLLOW-UP] Requesting streaming follow-up questions');
      print('[FOLLOW-UP] Session: ${state.sessionId}');
      print(
        '[FOLLOW-UP] Transcript length: ${state.fullTranscript.length} chars',
      );

      // Start with empty message and add it to conversation
      final scoutMessageId = _addScoutResponse(
        '',
        AssistantMessageType.followUp,
      );

      // DON'T change state - keep continuous listening active
      // Just update loading and timestamp
      state = state.copyWith(helpTimestamp: DateTime.now(), error: null);

      // Stream follow-up response
      String accumulatedResponse = '';
      await for (final chunk in _interviewService.getFollowUpQuestionsStreaming(
        request,
      )) {
        if (chunk.startsWith('Error:')) {
          print('[FOLLOW-UP] Follow-up request failed: $chunk');
          // Update the message with error
          _updateScoutResponse(scoutMessageId, chunk);
          break;
        } else {
          // Accumulate the streaming response
          accumulatedResponse += chunk;
          print('[FOLLOW-UP] Received chunk: "$chunk"');
          print(
            '[FOLLOW-UP] Accumulated length: ${accumulatedResponse.length} chars',
          );

          // Update the Scout message with current accumulated content
          _updateScoutResponse(scoutMessageId, accumulatedResponse);

          // Update help response in state for legacy compatibility
          state = state.copyWith(helpResponse: accumulatedResponse);
        }
      }

      print(
        '[FOLLOW-UP] Streaming completed. Final response length: ${accumulatedResponse.length} chars',
      );

      // Mark help as complete
      state = state.copyWith(isGettingHelp: false);
    } catch (e) {
      print('[FOLLOW-UP] Error getting streaming follow-up: $e');
      state = state.copyWith(
        isGettingHelp: false,
        error: 'Failed to get follow-up questions: ${e.toString()}',
      );
    }
  }

  // Start session with API integration
  Future<bool> startSessionWithAPI({
    String? sessionId,
    required String sessionType,
    required String role,
    required String companyName,
    required String jobDescription,
    String language = "en",
    String? resumeText,
  }) async {
    try {
      // Set loading state
      state = state.copyWith(isStartingSession: true, error: null);

      // Create API request
      final request = SessionStartRequest(
        sessionId: sessionId,
        sessionType: sessionType,
        role: role,
        companyName: companyName,
        jobDescription: jobDescription,
        language: language,
        resumeText: resumeText,
      );

      print('[API] Starting session with backend...');
      final response = await _interviewService.startSession(request);

      if (response.success) {
        print(
          '[API] Session started successfully. Session ID: ${response.sessionId}',
        );

        // Store session metadata in state
        state = state.copyWith(
          sessionId: response.sessionId,
          sessionType: sessionType,
          role: role,
          companyName: companyName,
          jobDescription: jobDescription,
          language: language,
          resumeText: resumeText,
          isStartingSession: false,
          error: null,
        );

        return true;
      } else {
        print('[API] Session start failed: ${response.error}');
        state = state.copyWith(
          isStartingSession: false,
          error: response.error ?? 'Failed to start session with backend',
        );
        return false;
      }
    } catch (e) {
      print('[API] Session start error: $e');
      state = state.copyWith(
        isStartingSession: false,
        error: 'Failed to connect to server: ${e.toString()}',
      );
      return false;
    }
  }

  // Get help with current transcript (now using streaming)
  Future<void> getHelp() async {
    // Only allow help if we have a session ID and some transcript
    if (state.sessionId == null || state.sessionId!.isEmpty) {
      state = state.copyWith(
        error: 'No active session. Please start a session first.',
      );
      return;
    }

    final transcript = state.fullTranscript.trim();
    if (transcript.isEmpty) {
      state = state.copyWith(
        error: 'No transcript available. Please record some speech first.',
      );
      return;
    }

    try {
      // Set loading state
      state = state.copyWith(isGettingHelp: true, error: null);

      // Create help request
      final request = SessionHelpRequest(
        sessionId: state.sessionId!,
        transcript: transcript,
      );

      print('[HELP] Requesting streaming help');
      print('[HELP] Session: ${state.sessionId}');
      print('[HELP] Transcript length: ${transcript.length} chars');

      // Start with empty message and add it to conversation
      final scoutMessageId = _addScoutResponse('', AssistantMessageType.help);

      // DON'T change state - keep continuous listening active
      // Just update loading and timestamp
      state = state.copyWith(helpTimestamp: DateTime.now(), error: null);

      // Stream help response
      String accumulatedResponse = '';
      await for (final chunk in _interviewService.getHelpStreaming(request)) {
        if (chunk.startsWith('Error:')) {
          print('[HELP] Help request failed: $chunk');
          // Update the message with error
          _updateScoutResponse(scoutMessageId, chunk);
          break;
        } else {
          // Accumulate the streaming response
          accumulatedResponse += chunk;
          print('[HELP] Received chunk: "$chunk"');
          print(
            '[HELP] Accumulated length: ${accumulatedResponse.length} chars',
          );

          // Update the Scout message with current accumulated content
          _updateScoutResponse(scoutMessageId, accumulatedResponse);

          // Update help response in state for legacy compatibility
          state = state.copyWith(helpResponse: accumulatedResponse);
        }
      }

      print(
        '[HELP] Streaming completed. Final response length: ${accumulatedResponse.length} chars',
      );

      // Mark help as complete
      state = state.copyWith(isGettingHelp: false);
    } catch (e) {
      print('[HELP] Error getting streaming help: $e');
      state = state.copyWith(
        isGettingHelp: false,
        error: 'Failed to get help from AI assistant: ${e.toString()}',
      );
    }
  }

  // Clear help response
  void clearHelpResponse() {
    state = state.copyWith(helpResponse: null, helpTimestamp: null);
  }

  // Clear error state (useful for dismissing dialogs)
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Legacy methods for compatibility (now no-ops with continuous listening)
  Future<void> startRecording() async {
    // No-op: Continuous listening means always recording
  }

  Future<void> stopRecordingAndProcess() async {
    // No-op: Continuous listening means never manually stopping
  }

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
    print('[DISPOSE] Cleaning up InterviewSessionNotifier');

    // Cancel session timer
    _sessionTimer?.cancel();
    _sessionTimer = null;

    // Remove listener and dispose RobustSpeechManager
    _speechManager.removeListener(_onSpeechUpdate);
    _speechManager.dispose();

    // Clear the state
    state = InterviewSessionData(); // Reset to initial state

    print('[DISPOSE] Cleanup completed');
    super.dispose();
  }
}

final interviewSessionProvider =
    StateNotifierProvider<InterviewSessionNotifier, InterviewSessionData>(
      (ref) => InterviewSessionNotifier(),
    );
