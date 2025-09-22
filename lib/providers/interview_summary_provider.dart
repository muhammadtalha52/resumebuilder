import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/interview_summary_model.dart';
import '../models/conversation_models.dart';
import '../services/interview_service.dart';
import 'interview_session_provider.dart';
import 'continuous_transcription_provider.dart';

final interviewServiceProvider = Provider<InterviewService>((ref) {
  return InterviewService();
});

class InterviewSummaryState {
  final bool isLoading;
  final InterviewSummaryModel? summary;
  final String? error;
  final bool isSaving;
  final bool hasSaved;

  InterviewSummaryState({
    this.isLoading = false,
    this.summary,
    this.error,
    this.isSaving = false,
    this.hasSaved = false,
  });

  InterviewSummaryState copyWith({
    bool? isLoading,
    InterviewSummaryModel? summary,
    String? error,
    bool? isSaving,
    bool? hasSaved,
  }) {
    return InterviewSummaryState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      error: error,
      isSaving: isSaving ?? this.isSaving,
      hasSaved: hasSaved ?? this.hasSaved,
    );
  }
}

class InterviewSummaryNotifier extends StateNotifier<InterviewSummaryState> {
  final InterviewService _interviewService;
  final Ref _ref;

  InterviewSummaryNotifier(this._interviewService, this._ref)
    : super(InterviewSummaryState());

  Future<void> endSessionAndGetSummary({
    required String sessionId,
    required String sessionType,
    required DateTime startTime,
    required Duration duration,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _interviewService.endSession(sessionId);

      if (response['status'] == 'success' && response['summary'] != null) {
        final summary = InterviewSummaryModel.fromApiResponse(
          sessionId: sessionId,
          sessionType: sessionType,
          startTime: startTime,
          duration: duration,
          summary: response['summary'],
        );

        state = state.copyWith(isLoading: false, summary: summary, error: null);

        // Summary loaded successfully - save button will trigger save
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['summary'] ?? 'Failed to get session summary',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error ending session: ${e.toString()}',
      );
    }
  }

  Future<void> saveInterviewData() async {
    if (state.isSaving || state.hasSaved) return;

    state = state.copyWith(isSaving: true, error: null);
    final transcriptionData = _ref.read(continuousTranscriptionProvider);

    // DEBUG: Print what we're getting
    print('[SAVE] DEBUG transcriptionData:');
    print(
      '  - fullTranscript length: ${transcriptionData.fullTranscript?.length ?? 0}',
    );
    print('  - helpResponse: ${transcriptionData.helpResponse}');
    print(
      '  - conversation.messages length: ${transcriptionData.conversation.messages.length}',
    );
    print('  - helpTimestamp: ${transcriptionData.helpTimestamp}');

    if (state.summary != null) {
      try {
        // Update session data with summary information
        _ref
            .read(interviewSessionProvider.notifier)
            .addSummary(
              keyTopics: state.summary!.keyTopics,
              strengthHighlight: state.summary!.strengths,
              weaknessHighlight: state.summary!.areasForImprovement,
              actionItems: state.summary!.actionItems,
            );

        // Simple: fullTranscript + helpResponse (if exists)
        String completeTranscript = transcriptionData.fullTranscript ?? '';

        if (transcriptionData.helpResponse != null &&
            transcriptionData.helpResponse!.isNotEmpty) {
          if (completeTranscript.isNotEmpty) {
            completeTranscript += '\n\n--- Scout AI Responses ---\n\n';
          }
          completeTranscript += transcriptionData.helpResponse!;
        }

        // Update the transcript field directly
        _ref.read(interviewSessionProvider.notifier).state = _ref
            .read(interviewSessionProvider)
            .copyWith(transcript: completeTranscript);

        // Get updated session data
        final updatedSessionData = _ref.read(interviewSessionProvider);

        // Save to database
        final result = await _interviewService.saveInterview(
          updatedSessionData,
        );

        if (result['status'] == 'success') {
          print('Interview saved successfully: ${result['message']}');
          _ref.read(interviewSessionProvider.notifier).markAsSaved();
          state = state.copyWith(isSaving: false, hasSaved: true);
        } else {
          print('Failed to save interview: ${result['message']}');
          state = state.copyWith(
            isSaving: false,
            error: result['message'] ?? 'Failed to save interview',
          );
        }
      } catch (e) {
        print('Error saving interview: $e');
        state = state.copyWith(
          isSaving: false,
          error: 'Error saving interview: ${e.toString()}',
        );
      }
    } else {
      state = state.copyWith(
        isSaving: false,
        error: 'Missing summary or session data',
      );
    }
  }

  void reset() {
    state = InterviewSummaryState();
  }
}

final interviewSummaryProvider =
    StateNotifierProvider<InterviewSummaryNotifier, InterviewSummaryState>((
      ref,
    ) {
      final interviewService = ref.watch(interviewServiceProvider);
      return InterviewSummaryNotifier(interviewService, ref);
    });
