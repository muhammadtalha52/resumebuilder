import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/conversation_models.dart';
import '../models/meeting_summary_model.dart';
import '../services/interview_service.dart';
import '../services/in_app_review_service.dart';
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
      // Get the full transcript from transcription provider
      final transcriptionData = _ref.read(continuousTranscriptionProvider);
      final fullTranscript = transcriptionData.fullTranscript;

      print(
        '[END-SESSION] Sending transcript to backend: ${fullTranscript.length} chars',
      );

      // Pass transcript to endSession so backend can generate summary
      final response = await _interviewService.endSession(
        sessionId,
        transcription: fullTranscript,
      );

      if (response['status'] == 'success') {
        // Debug: Print all keys in response
        print('[END-SESSION] Response keys: ${response.keys.toList()}');
        print(
          '[END-SESSION] Raw meetingSummary value: ${response['meetingSummary']}',
        );
        print(
          '[END-SESSION] Raw meeting_summary value: ${response['meeting_summary']}',
        );

        // Parse response and add session metadata
        final meetingSummaryModel = MeetingSummaryModel.fromJson(response)
            .copyWith(
              sessionId: sessionId,
              sessionType: sessionType,
              startTime: startTime,
              duration: duration,
            );

        final summaryPreview = meetingSummaryModel.meetingSummary != null
            ? meetingSummaryModel.meetingSummary!.substring(
                0,
                meetingSummaryModel.meetingSummary!.length > 100
                    ? 100
                    : meetingSummaryModel.meetingSummary!.length,
              )
            : 'null';
        print('[END-SESSION] meetingSummary: $summaryPreview...');

        // Check if we have either summary object or meetingSummary markdown
        if (meetingSummaryModel.summary != null ||
            (meetingSummaryModel.meetingSummary != null &&
                meetingSummaryModel.meetingSummary!.isNotEmpty)) {
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

        // NEW: Use JSON format for conversation entries (unified structure)
        String transcriptToSave;
        if (transcriptionData.conversationEntries.isNotEmpty) {
          // Encode entries as JSON for structured display
          transcriptToSave = ConversationEntry.encodeList(
            transcriptionData.conversationEntries,
          );
          print(
            '[SAVE] Using JSON format with ${transcriptionData.conversationEntries.length} entries',
          );
        } else {
          // Fallback to old format if no entries captured
          transcriptToSave = transcriptionData.fullTranscript;
          if (transcriptionData.conversation.messages.isNotEmpty) {
            if (transcriptToSave.isNotEmpty) {
              transcriptToSave += '\n\n--- Scout AI Responses ---\n\n';
            }
            for (var element in transcriptionData.conversation.messages) {
              if (element.content.isNotEmpty) {
                transcriptToSave += element.content;
              }
            }
          }
          print('[SAVE] Using legacy format (no entries captured)');
        }

        final nowDateTime = DateTime.now().toUtc().toIso8601String();
        // Get updated session data
        final sessionData = _ref.read(interviewSessionProvider);

        // Get duration from the model (passed from the summary screen)
        final durationMinutes =
            state.meetingSummaryModel!.duration?.inMinutes ?? 0;

        print('[SAVE] Duration: $durationMinutes min, DateTime: $nowDateTime');

        var dataToApi = {
          'company_name': sessionData.companyName.isEmpty
              ? "Test"
              : sessionData.companyName,
          'position_title': sessionData.positionTitle,
          'interview_type': sessionData.interviewType.toLowerCase(),
          'role_industry': sessionData.roleIndustry,
          'job_description': sessionData.jobDescription,
          "interview_date": nowDateTime,
          "duration_minutes": durationMinutes,
          "transcript": transcriptToSave,
          "language_selector": "English",
          "status": "scheduled",
          "location": "https://meet.google.com/abc-defg-hij",
          "interviewer_name": "",
          "interviewer_email": "",
          "notes": _getNotesForSessionType(
            sessionData.interviewType.toLowerCase(),
            summary,
          ),
        };

        // Save to database
        final result = await _interviewService.saveInterview(dataToApi);

        if (result['status'] == 'success') {
          print('Meeting saved successfully: ${result['message']}');
          _ref.read(interviewSessionProvider.notifier).markAsSaved();
          state = state.copyWith(isSaving: false, hasSaved: true);

          // Request in-app review (non-blocking, only shows once)
          InAppReviewService().requestReview();
        } else {
          print('Failed to save : ${result['message']}');
          state = state.copyWith(
            isSaving: false,
            error: result['message'] ?? 'Failed to save',
          );
        }
      } catch (e) {
        print('Error saving : $e');
        state = state.copyWith(
          isSaving: false,
          error: 'Error saving : ${e.toString()}',
        );
      }
    } else {
      state = state.copyWith(
        isSaving: false,
        error: 'Missing summary or session data',
      );
    }
  }

  /// Returns the appropriate notes/summary content based on session type
  String? _getNotesForSessionType(String sessionType, Summary summary) {
    // Check for practice/prep sessions
    if (sessionType.contains('prep') || sessionType.contains('practice')) {
      return summary.interviewPrepSummary;
    }
    // Check for interview sessions
    if (sessionType.contains('interview')) {
      return summary.interviewSummary;
    }
    // Default to meeting summary
    return summary.meetingSummary;
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
