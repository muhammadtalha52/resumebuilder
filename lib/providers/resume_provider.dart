import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/resume_model.dart';
import '../services/resume_service.dart';

class ResumeState {
  final bool isLoading;
  final String? error;
  final List<Resume> resumes;
  final Resume? selectedResume;
  final File? uploadedFile;

  ResumeState({
    this.isLoading = false,
    this.error,
    this.resumes = const [],
    this.selectedResume,
    this.uploadedFile,
  });

  ResumeState copyWith({
    bool? isLoading,
    String? error,
    List<Resume>? resumes,
    Resume? selectedResume,
    File? uploadedFile,
  }) {
    return ResumeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      resumes: resumes ?? this.resumes,
      selectedResume: selectedResume ?? this.selectedResume,
      uploadedFile: uploadedFile ?? this.uploadedFile,
    );
  }
}

class ResumeNotifier extends StateNotifier<ResumeState> {
  final ResumeService _resumeService;

  ResumeNotifier(this._resumeService) : super(ResumeState());

  Future<void> pickResumeFile() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Check file size (10MB limit)
        final fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          state = state.copyWith(
            isLoading: false,
            error: 'File size must be less than 10MB',
          );
          return;
        }

        state = state.copyWith(isLoading: false, uploadedFile: file);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to pick file: ${e.toString()}',
      );
    }
  }

  Future<void> uploadResume() async {
    if (state.uploadedFile == null) {
      state = state.copyWith(error: 'No file selected');
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Extract resume data using the resume service
      final resumeData = await _resumeService.extractResumeData(
        state.uploadedFile!,
      );

      state = state.copyWith(isLoading: false, uploadedFile: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to upload resume: ${e.toString()}',
      );
    }
  }

  Future<void> fetchResumes() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // TODO: Implement actual API call to fetch user's resumes
      // This would be a different endpoint to get all user resumes

      state = state.copyWith(isLoading: false, resumes: []);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch resumes: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearUploadedFile() {
    state = state.copyWith(uploadedFile: null);
  }
}

final resumeServiceProvider = Provider<ResumeService>((ref) {
  return ResumeService();
});

final resumeProvider = StateNotifierProvider<ResumeNotifier, ResumeState>((
  ref,
) {
  final resumeService = ref.watch(resumeServiceProvider);
  return ResumeNotifier(resumeService);
});
