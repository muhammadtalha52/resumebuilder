import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/interview_session_data.dart';

/// Notifier for managing the complete interview session lifecycle
class InterviewSessionNotifier extends StateNotifier<InterviewSessionData> {
  InterviewSessionNotifier() : super(InterviewSessionData());

  /// Update setup phase data
  void updateSetupData({
    String? companyName,
    String? positionTitle,
    String? interviewType,
    String? roleIndustry,
    String? jobDescription,
    String? languageSelector,
    String? interviewerName,
    String? interviewerEmail,
    String? location,
    String? notes,
    String? meetingAgenda,
  }) {
    state = state.copyWith(
      companyName: companyName,
      positionTitle: positionTitle,
      interviewType: interviewType,
      roleIndustry: roleIndustry,
      jobDescription: jobDescription,
      languageSelector: languageSelector,
      interviewerName: interviewerName,
      interviewerEmail: interviewerEmail,
      location: location,
      notes: notes,
      meetingAgenda: meetingAgenda,
    );
  }

  /// Start the interview session
  void startSession({required String sessionId, DateTime? startTime}) {
    state = state.startSession(sessionId: sessionId, startTime: startTime);
  }

  /// End the interview session
  void endSession({DateTime? endTime, String? fullTranscript}) {
    state = state.endSession(endTime: endTime, fullTranscript: fullTranscript);
  }

  /// Add summary data from AI analysis
  void addSummary({
    required List<String> keyTopics,
    required List<String> strengthHighlight,
    required List<String> weaknessHighlight,
    required List<String> actionItems,
    String? rawSummary,
  }) {
    state = state.addSummary(
      keyTopics: keyTopics,
      strengthHighlight: strengthHighlight,
      weaknessHighlight: weaknessHighlight,
      actionItems: actionItems,
      rawSummary: rawSummary,
    );
  }

  /// Mark session as saved to database
  void markAsSaved() {
    state = state.markAsSaved();
  }

  /// Update session status
  void updateStatus(String status) {
    state = state.copyWith(status: status);
  }

  /// Update session ID
  void updateSessionId(String sessionId) {
    state = state.copyWith(sessionId: sessionId);
  }

  /// Update full transcript
  void updateTranscript(String transcript) {
    state = state.copyWith(fullTranscript: transcript);
  }

  /// Reset to new session (clear all data)
  void resetSession() {
    state = InterviewSessionData();
  }

  /// Reset only session runtime data (keep setup data)
  void resetSessionRuntime() {
    state = state.copyWith(
      sessionId: null,
      startTime: null,
      endTime: null,
      duration: null,
      status: 'setup',
      fullTranscript: null,
      keyTopics: [],
      strengthHighlight: [],
      weaknessHighlight: [],
      actionItems: [],
      rawSummary: null,
      saved: false,
      savedAt: null,
    );
  }

  /// Load session from JSON (for persistence)
  void loadFromJson(Map<String, dynamic> json) {
    state = InterviewSessionData.fromJson(json);
  }

  /// Get current session data as JSON (for persistence)
  Map<String, dynamic> toJson() {
    return state.toJson();
  }

  /// Get API-ready JSON for saving to database
  Map<String, dynamic> toApiJson() {
    return state.toApiJson();
  }

  /// Prepare transcript with both listened content and Scout responses for API
  void prepareCompleteTranscript(
    String? listenedTranscript,
    String? scoutResponses,
  ) {
    String completeTranscript = '';

    // Add everything we listened from the interviewer
    if (listenedTranscript != null && listenedTranscript.isNotEmpty) {
      completeTranscript = listenedTranscript;
    }

    // Add all Scout responses
    if (scoutResponses != null && scoutResponses.isNotEmpty) {
      if (completeTranscript.isNotEmpty) {
        completeTranscript += '\n\n--- Scout AI Responses ---\n\n';
      }
      completeTranscript += scoutResponses;
    }

    // Update the transcript field with the complete merged content
    state = state.copyWith(transcript: completeTranscript);
  }

  /// Check if setup is complete and ready to start session
  bool get isReadyToStart => state.isSetupComplete;

  /// Check if session is currently active
  bool get isSessionActive => state.isSessionActive;

  /// Check if session is completed
  bool get isSessionCompleted => state.isSessionCompleted;

  /// Get session duration
  Duration get sessionDuration => state.calculatedDuration;

  /// Get session ID
  String? get sessionId => state.sessionId;

  /// Get session status
  String get sessionStatus => state.status;

  /// Check if session has been saved
  bool get isSaved => state.saved;

  /// Set error state
  void setError(String error) {
    state = state.copyWith(error: error);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Global provider for interview session management
final interviewSessionProvider =
    StateNotifierProvider<InterviewSessionNotifier, InterviewSessionData>((
      ref,
    ) {
      return InterviewSessionNotifier();
    });

/// Convenience providers for specific data access
final interviewSetupDataProvider = Provider<InterviewSessionData>((ref) {
  return ref.watch(interviewSessionProvider);
});

final interviewSessionIdProvider = Provider<String?>((ref) {
  return ref.watch(interviewSessionProvider).sessionId;
});

final interviewSessionStatusProvider = Provider<String>((ref) {
  return ref.watch(interviewSessionProvider).status;
});

final interviewSessionDurationProvider = Provider<Duration>((ref) {
  return ref.watch(interviewSessionProvider).calculatedDuration;
});

final interviewSummaryDataProvider = Provider<Map<String, List<String>>>((ref) {
  final session = ref.watch(interviewSessionProvider);
  return {
    'keyTopics': session.keyTopics,
    'strengths': session.strengthHighlight,
    'weaknesses': session.weaknessHighlight,
    'actionItems': session.actionItems,
  };
});

final isInterviewSetupCompleteProvider = Provider<bool>((ref) {
  return ref.watch(interviewSessionProvider).isSetupComplete;
});

final isInterviewSessionActiveProvider = Provider<bool>((ref) {
  return ref.watch(interviewSessionProvider).isSessionActive;
});

final isInterviewSessionCompletedProvider = Provider<bool>((ref) {
  return ref.watch(interviewSessionProvider).isSessionCompleted;
});

final isInterviewSavedProvider = Provider<bool>((ref) {
  return ref.watch(interviewSessionProvider).saved;
});
