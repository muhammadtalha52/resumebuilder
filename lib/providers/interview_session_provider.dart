import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/interview_session_data.dart';
import '../services/resume_service.dart';
import '../utils/s3_utils.dart';

/// Notifier for managing the complete interview session lifecycle
class InterviewSessionNotifier extends StateNotifier<InterviewSessionData> {
  InterviewSessionNotifier() : super(InterviewSessionData());

  /// Track current extraction request to prevent race conditions
  int _currentExtractionId = 0;

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
    int? selectedResumeId,
    String? selectedResumeTitle,
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
      selectedResumeId: selectedResumeId,
      selectedResumeTitle: selectedResumeTitle,
    );
  }

  /// Mark session as saved to database
  void markAsSaved() {
    state = state.markAsSaved();
  }

  /// Extract resume data from URL (for history resumes and profile resume)
  Future<void> extractResumeFromUrl(String resumeUrl) async {
    if (resumeUrl.isEmpty) return;

    // Increment ID to cancel any previous extraction in progress
    final requestId = ++_currentExtractionId;

    // Set loading state and clear previous data
    state = state.copyWith(
      isExtractingResume: true,
      extractedResumeData: null,
      error: null,
    );

    try {
      // If it's a relative path, construct the full S3 URL
      String fullUrl = resumeUrl;
      if (!resumeUrl.startsWith('http')) {
        fullUrl = S3Utils.constructAssetUrl(resumeUrl);
      }
      print('[RESUME] Starting extraction from URL: $fullUrl');

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final tempFilePath =
          '${tempDir.path}/temp_resume_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final tempFile = File(tempFilePath);

      // Download the file
      print('[RESUME] Downloading to: $tempFilePath');
      final dio = Dio();
      await dio.download(fullUrl, tempFilePath);

      // Ignore if user selected a different resume
      if (requestId != _currentExtractionId) {
        print('[RESUME] Ignoring stale extraction result');
        try {
          await tempFile.delete();
        } catch (_) {}
        return;
      }

      // Check if file was downloaded successfully
      if (!await tempFile.exists()) {
        throw Exception('Failed to download resume file');
      }

      print(
        '[RESUME] Download complete, file size: ${await tempFile.length()} bytes',
      );

      // Extract resume data using ResumeService
      final resumeService = ResumeService();
      final extractedData = await resumeService.extractResumeData(tempFile);

      // Ignore if user selected a different resume
      if (requestId != _currentExtractionId) {
        print('[RESUME] Ignoring stale extraction result');
        try {
          await tempFile.delete();
        } catch (_) {}
        return;
      }

      // Convert to JSON string
      final jsonData = jsonEncode(extractedData.toJson());
      print('[RESUME] Extraction complete, data length: ${jsonData.length}');

      state = state.copyWith(
        extractedResumeData: jsonData,
        isExtractingResume: false,
      );

      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (e) {
        print('[RESUME] Failed to delete temp file: $e');
      }
    } catch (e) {
      // Only set error if this is still the current request
      if (requestId == _currentExtractionId) {
        print('[RESUME] Extraction error: $e');
        state = state.copyWith(
          isExtractingResume: false,
          error: 'Failed to extract resume data',
        );
      }
    }
  }

  /// Extract resume data from a local file (uploaded)
  Future<void> extractResumeFromFile(File file) async {
    // Increment ID to cancel any previous extraction in progress
    final requestId = ++_currentExtractionId;

    // Set loading state and clear previous data
    state = state.copyWith(
      isExtractingResume: true,
      extractedResumeData: null,
      error: null,
    );

    try {
      print('[RESUME] Extracting from local file: ${file.path}');

      // Extract resume data using ResumeService
      final resumeService = ResumeService();
      final extractedData = await resumeService.extractResumeData(file);

      // Ignore if user selected a different resume
      if (requestId != _currentExtractionId) {
        print('[RESUME] Ignoring stale extraction result');
        return;
      }

      // Convert to JSON string
      final jsonData = jsonEncode(extractedData.toJson());
      print('[RESUME] Extraction complete, data length: ${jsonData.length}');

      state = state.copyWith(
        extractedResumeData: jsonData,
        isExtractingResume: false,
      );
    } catch (e) {
      // Only set error if this is still the current request
      if (requestId == _currentExtractionId) {
        print('[RESUME] Extraction error: $e');
        state = state.copyWith(
          isExtractingResume: false,
          error: 'Failed to extract resume data',
        );
      }
    }
  }

  /// Extract resume using S3 filename (constructs URL automatically)
  Future<void> extractResumeFromS3FileName(String s3FileName) async {
    final url = S3Utils.constructAssetUrl(s3FileName);
    await extractResumeFromUrl(url);
  }

  /// Clear resume selection and extracted data
  void clearResumeSelection() {
    state = state.copyWith(
      selectedResumeId: null,
      selectedResumeTitle: null,
      extractedResumeData: null,
      isExtractingResume: false,
    );
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
