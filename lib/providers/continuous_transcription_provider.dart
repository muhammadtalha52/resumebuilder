import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/interview_service.dart';
import '../models/interview_session_models.dart';
import '../models/conversation_models.dart';
import '../screens/interview/continuous_audio_transcriber.dart';

// Re-export TranscriptionState for use in UI
export '../screens/interview/continuous_audio_transcriber.dart'
    show TranscriptionState;

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

  // Transcription data from ContinuousAudioTranscriber
  final String fullTranscript; // Complete transcript from all chunks
  final String latestSegment; // Latest transcribed segment (highlighted)
  final String?
  currentTranscription; // Live partial transcription (for compatibility)

  final bool isListening;
  final String? error;

  // Audio transcriber status
  final TranscriptionState? transcriptionState;
  final int chunkCount;
  final int pendingChunks;

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
    this.latestSegment = '',
    this.currentTranscription,
    this.isListening = false,
    this.error,
    this.transcriptionState,
    this.chunkCount = 0,
    this.pendingChunks = 0,
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
    String? latestSegment,
    String? currentTranscription,
    bool? isListening,
    String? error,
    TranscriptionState? transcriptionState,
    int? chunkCount,
    int? pendingChunks,
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
      latestSegment: latestSegment ?? this.latestSegment,
      currentTranscription: currentTranscription,
      isListening: isListening ?? this.isListening,
      error: error,
      transcriptionState: transcriptionState ?? this.transcriptionState,
      chunkCount: chunkCount ?? this.chunkCount,
      pendingChunks: pendingChunks ?? this.pendingChunks,
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

class ContinuousTranscriptionNotifier
    extends StateNotifier<InterviewSessionData> {
  Timer? _sessionTimer;
  Timer? _updateBatchTimer;
  String? _pendingScoutMessageId;
  String _pendingScoutContent = '';
  late ContinuousAudioTranscriber _audioTranscriber;
  final InterviewService _interviewService = InterviewService();

  ContinuousTranscriptionNotifier() : super(InterviewSessionData()) {
    print('[INIT] ContinuousTranscriptionNotifier created with Whisper API');
    _audioTranscriber = ContinuousAudioTranscriber();
    _audioTranscriber.addListener(_onTranscriberUpdate);
  }

  // Listen to audio transcriber updates and sync with provider state
  void _onTranscriberUpdate() {
    state = state.copyWith(
      fullTranscript: _audioTranscriber.transcript,
      latestSegment: _audioTranscriber.latestSegment,
      isListening: _audioTranscriber.isRecording,
      transcriptionState: _audioTranscriber.state,
      chunkCount: _audioTranscriber.chunkCount,
      pendingChunks: _audioTranscriber.pendingChunks,
    );

    // Update conversation message with new transcript
    _updateCurrentConversationMessage(_audioTranscriber.transcript);
  }

  // Start interview session
  Future<void> startSession() async {
    print('StartSession called with ContinuousAudioTranscriber');

    // COMPLETE RESET - Clear everything from previous sessions
    print('[SESSION_RESET] Performing complete session reset');
    print('[SESSION_RESET] Current sessionId before reset: ${state.sessionId}');

    // Stop any ongoing transcription
    await _audioTranscriber.stopRecording();

    // Store session metadata before reset
    final currentSessionId = state.sessionId;
    final currentSessionType = state.sessionType;
    final currentRole = state.role;
    final currentCompanyName = state.companyName;
    final currentJobDescription = state.jobDescription;
    final currentLanguage = state.language;
    final currentResumeText = state.resumeText;

    // Reset the UI state but KEEP session metadata if it exists
    state = InterviewSessionData(
      sessionId: currentSessionId,
      sessionType: currentSessionType,
      role: currentRole,
      companyName: currentCompanyName,
      jobDescription: currentJobDescription,
      language: currentLanguage,
      resumeText: currentResumeText,
    ); // Reset but preserve API session data

    print('[SESSION_RESET] Session ID after reset: ${state.sessionId}');
    print(
      '[SESSION_RESET] All previous data cleared, keeping session metadata',
    );

    try {
      // Use record package's native permission handling instead of permission_handler
      print('Checking microphone permission via record package...');

      // Let the record package handle permissions natively during initialization
      // This often works better than permission_handler for audio recording

      // Initialize ContinuousAudioTranscriber
      print('Initializing ContinuousAudioTranscriber...');
      final initialized = await _audioTranscriber.initialize();
      if (!initialized) {
        print('Failed to initialize ContinuousAudioTranscriber');
        state = state.copyWith(
          error: 'Audio recording is not available on this device',
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

      // AUTO-START: Begin continuous recording immediately
      print(
        '[AUTO-START] Starting continuous audio transcription automatically',
      );
      _startNewConversationMessage();
      await _audioTranscriber.startRecording();
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

  // INSTANT STOP - UI responds immediately, cleanup happens in background
  Future<void> stopSession() async {
    print('[SESSION-STOP] 🔥 INSTANT STOP - UI reset immediately');

    // 1. IMMEDIATELY reset UI state - no waiting
    state = InterviewSessionData(
      state: InterviewSessionState.idle,
      sessionDuration: Duration.zero,
      questions: const [],
      conversation: ConversationData(),
      fullTranscript: '',
      latestSegment: '',
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

    // 2. Stop timer immediately
    _stopTimer();

    // 3. Force stop audio recording (don't await - it's instant now)
    _audioTranscriber.stopRecording();

    print('[SESSION-STOP] ⚡ UI reset complete - cleanup running in background');
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

  // Transition to listening state without resetting session data
  // Used when session ID already exists and we just need to start audio transcription
  Future<void> transitionToListening() async {
    print('[TRANSITION] Transitioning to listening state without reset');
    print('[TRANSITION] Current session ID: ${state.sessionId}');

    try {
      // Don't reset any session data, just transition state and start audio
      state = state.copyWith(
        state: InterviewSessionState.listening,
        isListening: true,
        error: null,
      );

      // Initialize and start audio transcriber
      print('[TRANSITION] Initializing audio transcriber...');
      final initialized = await _audioTranscriber.initialize();
      if (!initialized) {
        print('[TRANSITION] Failed to initialize audio transcriber');
        state = state.copyWith(
          error: 'Audio recording is not available on this device',
        );
        return;
      }

      // Start timer and audio transcription
      _startTimer();
      _startNewConversationMessage();
      await _audioTranscriber.startRecording();

      print('[TRANSITION] Successfully transitioned to listening state');
    } catch (e) {
      print('[TRANSITION] Error transitioning to listening: $e');
      state = state.copyWith(error: 'Failed to start audio: ${e.toString()}');
    }
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

  // Update current transcription (for compatibility)
  void updateTranscription(String transcription) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] updateTranscription called');
    print('  - New transcription: "$transcription"');
    print('  - Previous transcription: "${state.currentTranscription}"');
    state = state.copyWith(currentTranscription: transcription);
  }

  // Add text to full transcript (for compatibility)
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
          content: text,
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
    print('❓ [DEBUG] getFollowUpQuestions() method called');
    print('❓ [DEBUG] Session ID: ${state.sessionId}');
    print('❓ [DEBUG] Full transcript: "${state.fullTranscript}"');
    print('❓ [DEBUG] Full transcript length: ${state.fullTranscript.length}');
    print(
      '❓ [DEBUG] Audio transcriber transcript: "${_audioTranscriber.transcript}"',
    );

    if (state.sessionId == null) {
      print('❓ [DEBUG] ERROR: No active session');
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

          // Batch Scout message updates - only update every 10 chars or on punctuation
          if (accumulatedResponse.length - _pendingScoutContent.length >= 10 ||
              chunk.contains('.') ||
              chunk.contains('?') ||
              chunk.contains('!')) {
            _updateScoutResponse(scoutMessageId, accumulatedResponse);
            _pendingScoutContent = accumulatedResponse;
          }

          // Update help response in state for legacy compatibility
          state = state.copyWith(helpResponse: accumulatedResponse);
        }
      }

      // Final update to ensure complete response is shown
      _updateScoutResponse(scoutMessageId, accumulatedResponse);
      _pendingScoutContent = '';

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

  // Get help with current transcript (now using streaming with focused cutoff)
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
      // 1. IMMEDIATELY show Scout is responding (seamless UX)
      state = state.copyWith(isGettingHelp: true, error: null);
      final scoutMessageId = _addScoutResponse('', AssistantMessageType.help);
      state = state.copyWith(helpTimestamp: DateTime.now(), error: null);

      // 2. SET CUTOFF POINT - ignore chunks created after this moment
      _audioTranscriber.setHelpRequestCutoff();

      // 3. SECRETLY wait for chunks recorded up to the cutoff to complete
      await _audioTranscriber.waitForChunksUpToCutoff(maxWaitMs: 5000);

      // 4. Get the complete transcript with all context (from chunks ≤ cutoff)
      final completeTranscript = _audioTranscriber.transcript.trim();

      // Create help request with complete transcript
      final request = SessionHelpRequest(
        sessionId: state.sessionId!,
        transcript: completeTranscript,
      );

      print(
        '[HELP] Complete transcript length: ${completeTranscript.length} chars',
      );

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
          // Batch Scout message updates - only update every 10 chars or on punctuation
          if (accumulatedResponse.length - _pendingScoutContent.length >= 10 ||
              chunk.contains('.') ||
              chunk.contains('?') ||
              chunk.contains('!')) {
            _updateScoutResponse(scoutMessageId, accumulatedResponse);
            _pendingScoutContent = accumulatedResponse;
          }

          // Update help response in state for legacy compatibility
          state = state.copyWith(helpResponse: accumulatedResponse);
        }
      }

      // Final update to ensure complete response is shown
      _updateScoutResponse(scoutMessageId, accumulatedResponse);
      _pendingScoutContent = '';

      // 5. CLEAR CUTOFF - resume normal processing for future help requests
      _audioTranscriber.clearHelpRequestCutoff();

      // Mark help as complete
      state = state.copyWith(isGettingHelp: false);
    } catch (e) {
      print('[HELP] Error getting streaming help: $e');

      // Ensure cutoff is cleared even if there's an error
      _audioTranscriber.clearHelpRequestCutoff();

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
    print('[DISPOSE] Cleaning up ContinuousTranscriptionNotifier');

    // Cancel timers
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _updateBatchTimer?.cancel();
    _updateBatchTimer = null;

    // Remove listener and dispose audio transcriber
    _audioTranscriber.removeListener(_onTranscriberUpdate);
    _audioTranscriber.dispose();

    // Clear the state
    state = InterviewSessionData(); // Reset to initial state

    print('[DISPOSE] Cleanup completed');
    super.dispose();
  }
}

final continuousTranscriptionProvider =
    StateNotifierProvider<
      ContinuousTranscriptionNotifier,
      InterviewSessionData
    >((ref) => ContinuousTranscriptionNotifier());
