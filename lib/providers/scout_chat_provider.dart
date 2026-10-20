import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meeting_history_response.dart';
import '../models/scout_chat_models.dart';
import '../services/interview_service.dart';
import '../services/stripe_subscription_service.dart';
import 'stripe_subscription_provider.dart';
import 'user_provider.dart';

class ScoutChatNotifier extends StateNotifier<ScoutChatState> {
  final InterviewService _interviewService;
  final StripeSubscriptionService? _stripeService;
  final bool _isStudent;

  ScoutChatNotifier(
    this._interviewService, {
    StripeSubscriptionService? stripeService,
    bool isStudent = false,
  })  : _stripeService = stripeService,
        _isStudent = isStudent,
        super(ScoutChatState());

  /// Setup Scout chat session for a meeting
  Future<void> setupChatSession(MeetingHistoryItem meeting) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _interviewService.setupScoutChatSession(
        meeting.id,
        meeting,
      );

      if (response['status'] == 'success') {
        // Add initial greeting from Scout
        final initialMessage = ChatMessage.scout(
          "Hi! I'm Scout, your AI assistant. I've analyzed your ${meeting.isInterview ? 'interview' : 'meeting'} session. What would you like to know about it?",
        );

        state = state.copyWith(
          isLoading: false,
          isSessionSetup: true,
          sessionId: meeting.id,
          messages: [initialMessage],
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to setup Scout chat',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error setting up Scout chat: ${e.toString()}',
      );
    }
  }

  /// Send a message to Scout with streaming response
  Future<void> sendMessage(String message) async {
    if (!state.isSessionSetup || state.sessionId == null) {
      state = state.copyWith(error: 'Chat session not setup');
      return;
    }

    // Check if user has reached the question limit
    if (state.hasReachedLimit) {
      state = state.copyWith(
        error:
            'You have reached the maximum of ${state.maxQuestions} questions for this session.',
      );
      return;
    }

    // 1. Ask Scout questions are counted for Candidates (Students are not affected)
    final stripeService = _stripeService;
    if (!_isStudent && stripeService != null) {
      state = state.copyWith(isLoading: true, error: null);
      final hasCredit = await stripeService.deductAskScoutCredit(
        sessionId: state.sessionId!.toString(),
      );

      if (!hasCredit) {
        state = state.copyWith(
          isLoading: false,
          error:
              "You've used all your Ask Scout questions for this period. They come back when your plan renews, or you can switch to a bigger plan.",
        );
        return;
      }
    }

    // Increment question count
    final newQuestionCount = state.questionCount + 1;

    // Add user message to the conversation
    final userMessage = ChatMessage.user(message);
    final updatedMessages = [...state.messages, userMessage];

    state = state.copyWith(
      messages: updatedMessages,
      isLoading: true,
      error: null,
      questionCount: newQuestionCount,
    );

    try {
      // Use the actual streaming API
      final stream = _interviewService.sendScoutChatMessage(
        state.sessionId!,
        message,
      );

      String scoutResponseText = '';

      // Listen to the stream and accumulate the response
      await for (final chunk in stream) {
        scoutResponseText += chunk;

        // Update Scout message with accumulated response
        final scoutMessage = ChatMessage.scout(scoutResponseText);
        final messagesWithScout = [...updatedMessages, scoutMessage];

        state = state.copyWith(
          messages: messagesWithScout,
          isLoading: true, // Keep loading until stream completes
        );
      }

      // Stream completed, mark as not loading
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error sending message: ${e.toString()}',
      );
    }
  }

  /// Clear chat messages
  void clearChat() {
    state = state.copyWith(messages: [], error: null);
  }

  /// Reset chat session
  void resetSession() {
    state = ScoutChatState();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final interviewServiceProvider = Provider<InterviewService>((ref) {
  return InterviewService();
});

final scoutChatProvider =
    StateNotifierProvider.autoDispose<ScoutChatNotifier, ScoutChatState>((ref) {
  final interviewService = ref.watch(interviewServiceProvider);
  final isStudent = ref.read(isStudentProvider);
  final stripeService = ref.watch(stripeSubscriptionServiceProvider);

  return ScoutChatNotifier(
    interviewService,
    stripeService: stripeService,
    isStudent: isStudent,
  );
});
