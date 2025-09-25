import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meeting_summary_model.dart';
import '../services/interview_service.dart';
import 'continuous_transcription_provider.dart';
import 'interview_session_provider.dart';

final interviewServiceProvider = Provider<InterviewService>((ref) {
  return InterviewService();
});

class InterviewSummaryState {
  final bool isLoading;
  final MeetingSummaryModel? meetingSummaryModel;
  final String? error;
  final bool isSaving;
  final bool hasSaved;

  InterviewSummaryState({
    this.isLoading = false,
    this.meetingSummaryModel,
    this.error,
    this.isSaving = false,
    this.hasSaved = false,
  });

  InterviewSummaryState copyWith({
    bool? isLoading,
    MeetingSummaryModel? summary,
    String? error,
    bool? isSaving,
    bool? hasSaved,
  }) {
    return InterviewSummaryState(
      isLoading: isLoading ?? this.isLoading,
      meetingSummaryModel: summary ?? meetingSummaryModel,
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

      if (response['status'] == 'success') {
        // Parse response and add session metadata
        final meetingSummaryModel = MeetingSummaryModel.fromJson(response)
            .copyWith(
              sessionId: sessionId,
              sessionType: sessionType,
              startTime: startTime,
              duration: duration,
            );

        if (meetingSummaryModel.summary != null) {
          state = state.copyWith(
            isLoading: false,
            summary: meetingSummaryModel,
            error: null,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'No summary data received',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to get session summary',
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

    if (state.meetingSummaryModel != null &&
        state.meetingSummaryModel!.summary != null) {
      try {
        final summary = state.meetingSummaryModel!.summary!;
        // Simple: fullTranscript + helpResponse (if exists)
        String completeTranscriptAndScoutResponses =
            transcriptionData.fullTranscript;

        if (transcriptionData.conversation.messages.isNotEmpty) {
          if (completeTranscriptAndScoutResponses.isNotEmpty) {
            completeTranscriptAndScoutResponses +=
                '\n\n--- Scout AI Responses ---\n\n';
          }

          for (var element in transcriptionData.conversation.messages) {
            if (element.content.isNotEmpty) {
              completeTranscriptAndScoutResponses += element.content;
            }
          }
        }

        final nowDateTime =
            '${DateTime.now().toUtc().toIso8601String().split('.').first}Z';
        // Get updated session data
        final sessionData = _ref.read(interviewSessionProvider);
        var dataToApi = {
          'company_name': sessionData.companyName,
          'position_title': sessionData.positionTitle,
          'interview_type': sessionData.interviewType,
          'role_industry': sessionData.roleIndustry,
          'job_description': sessionData.jobDescription,
          "interview_date": nowDateTime,
          "duration_minutes": sessionData.duration ?? 20,
          "transcript": completeTranscriptAndScoutResponses,
          "key_topics": summary.keyDiscussionPoints,
          "strength_highlight": summary.strengthsHighlighted,
          "weakness_highlight": summary.potentialWeaknessOrStrengths,
          "action_items": summary.actionItems,
          "decisions_made": summary.decisionsMade,
          "top_moments_in_interview": summary.topMomentsInInterview,
          "ai_driven_interview_analytics": summary.aiDrivenInterviewAnalytics,
          "areas_of_improvement": summary.areasOfImprovement,
          "language_selector": "English",
          "status": "scheduled",
          "location": "https://meet.google.com/abc-defg-hij",
          "interviewer_name": "",
          "interviewer_email": "",
          "notes": "",
        };

        // Save to database
        final result = await _interviewService.saveInterview(dataToApi);

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
