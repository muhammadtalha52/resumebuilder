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

  /// Mark session as saved to database
  void markAsSaved() {
    state = state.markAsSaved();
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
