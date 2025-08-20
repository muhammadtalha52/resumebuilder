import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/resume_model.dart';
import '../models/resume_parse_model.dart';
import '../models/education_model.dart';
import '../services/resume_service.dart';
import '../services/education_service.dart';

class ResumeState {
  final bool isLoading;
  final bool isParsing;
  final bool isLoadingEducationData;
  final String? error;
  final List<Resume> resumes;
  final Resume? selectedResume;
  final File? uploadedFile;
  final ResumeParse? parsedResumeData;
  final bool isUsingProfileData; // New flag to indicate profile data mode
  final EducationModel? educationData; // Store education data for ID resolution

  ResumeState({
    this.isLoading = false,
    this.isParsing = false,
    this.isLoadingEducationData = false,
    this.error,
    this.resumes = const [],
    this.selectedResume,
    this.uploadedFile,
    this.parsedResumeData,
    this.isUsingProfileData = false,
    this.educationData,
  });

  ResumeState copyWith({
    bool? isLoading,
    bool? isParsing,
    bool? isLoadingEducationData,
    String? error,
    List<Resume>? resumes,
    Resume? selectedResume,
    File? uploadedFile,
    ResumeParse? parsedResumeData,
    bool? isUsingProfileData,
    EducationModel? educationData,
  }) {
    return ResumeState(
      isLoading: isLoading ?? this.isLoading,
      isParsing: isParsing ?? this.isParsing,
      isLoadingEducationData:
          isLoadingEducationData ?? this.isLoadingEducationData,
      error: error,
      resumes: resumes ?? this.resumes,
      selectedResume: selectedResume ?? this.selectedResume,
      uploadedFile: uploadedFile ?? this.uploadedFile,
      parsedResumeData: parsedResumeData ?? this.parsedResumeData,
      isUsingProfileData: isUsingProfileData ?? this.isUsingProfileData,
      educationData: educationData ?? this.educationData,
    );
  }
}

class ResumeNotifier extends StateNotifier<ResumeState> {
  final ResumeService _resumeService;
  final EducationService _educationService;

  ResumeNotifier(this._resumeService, this._educationService)
    : super(ResumeState());

  /// Pick resume file and automatically parse it
  Future<bool> pickAndParseResumeFile() async {
    try {
      print('🔄 Starting pickAndParseResumeFile...');
      // Clear any existing parsed data to ensure fresh parsing
      state = state.copyWith(
        isLoading: true,
        error: null,
        parsedResumeData: null,
      );
      print('✅ Set state to loading: true, parsedResumeData: null');

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
          return false;
        }

        // File selected successfully, now parse it
        print('📁 File selected: ${file.path}');
        state = state.copyWith(
          isLoading: false,
          uploadedFile: file,
          isParsing: true,
        );
        print('🔄 Set state to isParsing: true');
        final success = await _parseResumeFile(file);

        if (success) {
          print('✅ Parsing successful, setting final state');
          state = state.copyWith(
            isLoading: false,
            isParsing: false,
            uploadedFile: null,
          );
          print(
            '🎉 Final state: isLoading: false, isParsing: false, parsedResumeData: ${state.parsedResumeData != null}',
          );
          return true;
        } else {
          print('❌ Parsing failed');
          state = state.copyWith(isLoading: false, isParsing: false);
          return false;
        }
      } else {
        print('❌ No file selected');
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isParsing: false,
        error: 'Failed to pick file: ${e.toString()}',
      );
      return false;
    }
  }

  /// Parse the resume file and store the extracted data
  Future<bool> _parseResumeFile(File file) async {
    try {
      print('🔍 Starting resume parsing...');
      // Extract resume data using the resume service
      final resumeData = await _resumeService.extractResumeData(file);
      print('✅ Resume parsing completed successfully');
      print(
        '📄 Parsed data: ${resumeData.personal?.name ?? "No name"}, ${resumeData.workExperience.length} work experiences',
      );

      state = state.copyWith(parsedResumeData: resumeData);
      print('💾 Stored parsed data in state');
      return true;
    } catch (e) {
      print('❌ Resume parsing failed: $e');
      state = state.copyWith(error: 'Failed to parse resume: ${e.toString()}');
      return false;
    }
  }

  /// Legacy method for backwards compatibility
  Future<void> pickResumeFile() async {
    await pickAndParseResumeFile();
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

  void clearParsedData() {
    state = state.copyWith(parsedResumeData: null);
  }

  /// Set profile data mode for creating resume from existing profile
  void loadProfileDataMode() {
    print('📋 Setting profile data mode');
    state = state.copyWith(
      isUsingProfileData: true,
      parsedResumeData: null, // Clear any existing parsed data
      error: null,
    );
  }

  /// Clear profile data mode
  void clearProfileDataMode() {
    state = state.copyWith(isUsingProfileData: false);
  }

  /// Get parsed resume data for use in other screens
  ResumeParse? get parsedResumeData => state.parsedResumeData;

  /// Fetch education data for ID resolution
  Future<void> fetchEducationData() async {
    if (state.educationData != null) {
      // Already have education data, no need to fetch again
      return;
    }

    try {
      state = state.copyWith(isLoadingEducationData: true);
      print('🎓 Fetching education data for ID resolution...');

      final educationData = await _educationService.getEducationData();

      state = state.copyWith(
        isLoadingEducationData: false,
        educationData: educationData,
      );
      print('✅ Education data fetched successfully');
      print(
        '🔍 Available institutions: ${educationData.data?.institutes?.map((i) => 'ID:${i.id}="${i.name}"').join(", ")}',
      );
      print(
        '🔍 Available degree types: ${educationData.data?.degreeTypes?.map((dt) => 'ID:${dt.id}="${dt.name}"').join(", ")}',
      );
      print(
        '🔍 Available subjects: ${educationData.data?.subjects?.map((s) => 'ID:${s.id}="${s.name}"').join(", ")}',
      );
    } catch (e) {
      print('❌ Failed to fetch education data: $e');
      state = state.copyWith(
        isLoadingEducationData: false,
        error: 'Failed to fetch education data: ${e.toString()}',
      );
    }
  }

  /// Resolve institution ID to name
  String? resolveInstitutionName(int? institutionId) {
    if (institutionId == null ||
        state.educationData?.data?.institutes == null) {
      return null;
    }

    try {
      final institute = state.educationData!.data!.institutes!.firstWhere(
        (i) => i.id == institutionId,
      );
      return institute.name;
    } catch (e) {
      print('❌ Could not resolve institution ID $institutionId to name');
      return 'Institution ID: $institutionId';
    }
  }

  /// Resolve degree type ID to name
  String? resolveDegreeTypeName(int? degreeTypeId) {
    if (degreeTypeId == null ||
        state.educationData?.data?.degreeTypes == null) {
      return null;
    }

    try {
      final degreeType = state.educationData!.data!.degreeTypes!.firstWhere(
        (dt) => dt.id == degreeTypeId,
      );
      return degreeType.name;
    } catch (e) {
      print('❌ Could not resolve degree type ID $degreeTypeId to name');
      return 'Degree ID: $degreeTypeId';
    }
  }

  /// Resolve major ID to name
  String? resolveMajorName(int? majorId) {
    if (majorId == null || state.educationData?.data?.subjects == null) {
      return null;
    }

    try {
      final subject = state.educationData!.data!.subjects!.firstWhere(
        (s) => s.id == majorId,
      );
      return subject.name;
    } catch (e) {
      print('❌ Could not resolve major ID $majorId to name');
      return 'Major ID: $majorId';
    }
  }

  /// Resolve certification ID to name
  String? resolveCertificationName(int? certificationId) {
    if (certificationId == null ||
        state.educationData?.data?.certificates == null) {
      return null;
    }

    try {
      final certificate = state.educationData!.data!.certificates!.firstWhere(
        (c) => c.id == certificationId,
      );
      return certificate.name;
    } catch (e) {
      print('❌ Could not resolve certification ID $certificationId to name');
      return 'Certification ID: $certificationId';
    }
  }
}

final resumeServiceProvider = Provider<ResumeService>((ref) {
  return ResumeService();
});

final educationServiceProvider = Provider<EducationService>((ref) {
  return EducationService();
});

final resumeProvider = StateNotifierProvider<ResumeNotifier, ResumeState>((
  ref,
) {
  final resumeService = ref.watch(resumeServiceProvider);
  final educationService = ref.watch(educationServiceProvider);
  return ResumeNotifier(resumeService, educationService);
});
