import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/resume_model.dart';
import '../models/resume_parse_model.dart';
import '../models/education_model.dart';
import '../models/generate_resume_response.dart';
import '../services/resume_service.dart';
import '../services/education_service.dart';
import '../services/subscription_service.dart';
import '../services/api_client.dart';

class ResumeState {
  final bool isLoading;
  final bool isParsing;
  final bool isLoadingEducationData;
  final bool isGeneratingResume;
  final String? error;
  final List<Resume> resumes;
  final Resume? selectedResume;
  final File? uploadedFile;
  final ResumeParse? parsedResumeData;
  final bool isUsingProfileData; // New flag to indicate profile data mode
  final EducationModel? educationData; // Store education data for ID resolution
  final GenerateResumeResponse?
  generatedResumeData; // Store generated resume data
  final int resumeVersion; // Track resume updates for UI refresh

  ResumeState({
    this.isLoading = false,
    this.isParsing = false,
    this.isLoadingEducationData = false,
    this.isGeneratingResume = false,
    this.error,
    this.resumes = const [],
    this.selectedResume,
    this.uploadedFile,
    this.parsedResumeData,
    this.isUsingProfileData = false,
    this.educationData,
    this.generatedResumeData,
    this.resumeVersion = 0,
  });

  ResumeState copyWith({
    bool? isLoading,
    bool? isParsing,
    bool? isLoadingEducationData,
    bool? isGeneratingResume,
    String? error,
    List<Resume>? resumes,
    Resume? selectedResume,
    File? uploadedFile,
    ResumeParse? parsedResumeData,
    bool? isUsingProfileData,
    EducationModel? educationData,
    GenerateResumeResponse? generatedResumeData,
    int? resumeVersion,
  }) {
    return ResumeState(
      isLoading: isLoading ?? this.isLoading,
      isParsing: isParsing ?? this.isParsing,
      isLoadingEducationData:
          isLoadingEducationData ?? this.isLoadingEducationData,
      isGeneratingResume: isGeneratingResume ?? this.isGeneratingResume,
      error: error,
      resumes: resumes ?? this.resumes,
      selectedResume: selectedResume ?? this.selectedResume,
      uploadedFile: uploadedFile ?? this.uploadedFile,
      parsedResumeData: parsedResumeData ?? this.parsedResumeData,
      isUsingProfileData: isUsingProfileData ?? this.isUsingProfileData,
      educationData: educationData ?? this.educationData,
      generatedResumeData: generatedResumeData ?? this.generatedResumeData,
      resumeVersion: resumeVersion ?? this.resumeVersion,
    );
  }
}

class ResumeNotifier extends StateNotifier<ResumeState> {
  final ResumeService _resumeService;
  final EducationService _educationService;
  final SubscriptionService _subscriptionService;

  ResumeNotifier(
    this._resumeService,
    this._educationService,
    this._subscriptionService,
  ) : super(ResumeState());

  /// Pick resume file without parsing
  Future<bool> pickResumeFile() async {
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
          return false;
        }

        // File selected successfully, store it
        state = state.copyWith(
          isLoading: false,
          uploadedFile: file,
          isUsingProfileData:
              false, // Clear profile data mode when file is uploaded
          parsedResumeData: null, // Clear any existing parsed data
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to pick file: ${e.toString()}',
      );
      return false;
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

  void clearParsedData() {
    state = state.copyWith(parsedResumeData: null);
  }

  /// Set profile data mode for creating resume from existing profile
  void loadProfileDataMode() {
    print('📋 Setting profile data mode');
    state = state.copyWith(
      isUsingProfileData: true,
      parsedResumeData: null, // Clear any existing parsed data
      uploadedFile: null, // Clear any existing uploaded file
      error: null,
    );
  }

  /// Clear profile data mode
  void clearProfileDataMode() {
    state = state.copyWith(isUsingProfileData: false);
  }

  /// Reset all resume state for fresh start
  void resetResumeState() {
    print('🔄 Resetting all resume state');
    state = state.copyWith(
      uploadedFile: null,
      parsedResumeData: null,
      isUsingProfileData: false,
      generatedResumeData: null,
      error: null,
    );
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

  /// Regenerate specific sections of a resume
  Future<GenerateResumeResponse?> regenerateSections({
    required GenerateResumeResponse currentResumeData,
    required List<String> sectionsToRegenerate,
    String? jobUrl,
    String? jobDescription,
    required String template,
  }) async {
    try {
      state = state.copyWith(isGeneratingResume: true, error: null);

      print('🔄 Regenerating sections: ${sectionsToRegenerate.join(", ")}');
      print('Template: $template');
      print('Job URL: ${jobUrl ?? "None"}');

      // Convert current resume data to JSON string
      final resumeDataJson = jsonEncode(currentResumeData.toJson());

      final result = await _resumeService.regenerateSections(
        resumeData: resumeDataJson,
        sectionsToRegenerate: sectionsToRegenerate.join(','),
        jobUrl: jobUrl,
        jobDescription: jobDescription,
        template: template,
      );

      state = state.copyWith(
        isGeneratingResume: false,
        generatedResumeData: result,
      );

      print('✅ Sections regenerated successfully');
      return result;
    } catch (e) {
      print('❌ Error regenerating sections: $e');
      state = state.copyWith(isGeneratingResume: false, error: e.toString());
      return null;
    }
  }

  /// Generate a resume based on user data and job requirements
  Future<GenerateResumeResponse?> generateResume({
    required File file,
    String? jobUrl,
    String? jobDescription,
    required String template,
  }) async {
    try {
      state = state.copyWith(
        isGeneratingResume: true,
        error: null,
        generatedResumeData: null,
      );

      final result = await _resumeService.generateResume(
        file: file,
        jobUrl: jobUrl,
        jobDescription: jobDescription,
        template: template,
      );

      print("ResumeGenerated json :${result.resumeData.toString()}");
      print("ResumeGenerated base_64 :${result.pdfBase64}");

      state = state.copyWith(
        isGeneratingResume: false,
        generatedResumeData: result,
      );

      // Mark resume credit as used after successful generation
      print('✅ Resume generated successfully, marking credit as used');
      _subscriptionService
          .markCreditsUsed(
            resourceType: 'resume',
            count: 1,
            description: jobUrl != null && jobUrl.isNotEmpty
                ? 'Resume generated for job: $jobUrl'
                : jobDescription != null && jobDescription.isNotEmpty
                ? 'Resume generated with custom job description'
                : 'Resume generated',
            referenceId: file.path,
          )
          .then((success) {
            if (success) {
              print('✅ Resume credit marked as used successfully');
            } else {
              print('⚠️ Failed to mark resume credit as used');
            }
          })
          .catchError((e) {
            print('⚠️ Error marking resume credit as used: $e');
            // Silent fail - don't interrupt user experience
          });

      return result;
    } catch (e) {
      state = state.copyWith(isGeneratingResume: false, error: e.toString());
      return null;
    }
  }

  /// Clear generated resume data
  void clearGeneratedResumeData() {
    state = state.copyWith(generatedResumeData: null);
  }

  /// Update the generated resume data with edited content
  void updateGeneratedResume(GenerateResumeResponse updatedResumeData) {
    print('🔄 ResumeProvider.updateGeneratedResume called');
    print(
      '📋 Old PDF length: ${state.generatedResumeData?.pdfBase64?.length ?? 0}',
    );
    print('📋 New PDF length: ${updatedResumeData.pdfBase64?.length ?? 0}');
    print('📋 Old object hashCode: ${state.generatedResumeData?.hashCode}');
    print('📋 New object hashCode: ${updatedResumeData.hashCode}');
    print('📋 Old version: ${state.resumeVersion}');

    // Create a completely new instance to ensure Riverpod detects the change
    final newResumeData = GenerateResumeResponse(
      resumeData: updatedResumeData.resumeData,
      pdfBase64: updatedResumeData.pdfBase64,
      regeneratedSections: updatedResumeData.regeneratedSections,
    );

    // Increment version to force UI refresh
    final newVersion = state.resumeVersion + 1;
    print('📋 New version: $newVersion');
    print('📋 Final object hashCode: ${newResumeData.hashCode}');

    state = state.copyWith(
      generatedResumeData: newResumeData,
      resumeVersion: newVersion,
    );

    print(
      '✅ State updated - generatedResumeData hashCode: ${state.generatedResumeData?.hashCode}, version: ${state.resumeVersion}',
    );
  }

  /// Convert current resume data to PDF using specified template
  Future<String?> convertResumeToPdf({
    required GenerateResumeResponse currentResumeData,
    required String template,
  }) async {
    try {
      // Convert current resume data to JSON string
      final resumeDataJson = jsonEncode(currentResumeData.resumeData?.toJson());
      final pdfBase64 = await _resumeService.convertResumeToPdf(
        resumeData: resumeDataJson,
        template: template,
      );
      return pdfBase64;
    } catch (e) {
      return null;
    }
  }

  /// Save generated resume to backend with PDF upload to S3
  Future<Map<String, dynamic>?> saveGeneratedResume({
    String? companyName,
    String? jobTitle,
    String? linkedinJobUrl,
    String? jobDescription,
  }) async {
    File? tempPdfFile;
    try {
      // Check if we have generated resume data
      if (state.generatedResumeData == null) {
        state = state.copyWith(error: 'No resume data to save');
        return null;
      }

      final resumeData = state.generatedResumeData!.resumeData;
      final pdfBase64 = state.generatedResumeData!.pdfBase64;

      if (resumeData == null || pdfBase64 == null || pdfBase64.isEmpty) {
        state = state.copyWith(error: 'Invalid resume data or PDF');
        return null;
      }

      // Generate title based on user name and job title
      final userName = resumeData.personal?.name ?? 'Resume';
      final title = jobTitle != null && jobTitle.isNotEmpty
          ? '$userName - $jobTitle Resume'
          : '$userName Resume';

      state = state.copyWith(isLoading: true, error: null);

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      tempPdfFile = File('${tempDir.path}/resume_$timestamp.pdf');

      // Decode base64 to bytes and write to file
      final pdfBytes = base64Decode(pdfBase64);
      await tempPdfFile.writeAsBytes(pdfBytes);
      final saveDocResponse = await _resumeService.uploadDocsToS3(tempPdfFile);
      final result = await _resumeService.saveResume(
        title: title,
        companyName: companyName,
        jobTitle: jobTitle,
        linkedinJobUrl: linkedinJobUrl,
        jobDescription: jobDescription,
        resumeData: resumeData.toJson(),
        resumeUrl: saveDocResponse.s3FileName,
      );

      state = state.copyWith(isLoading: false);

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save resume: ${e.toString()}',
      );
      return null;
    } finally {
      // Clean up temporary file
      if (tempPdfFile != null && await tempPdfFile.exists()) {
        try {
          await tempPdfFile.delete();
        } catch (e) {}
      }
    }
  }
}

final resumeServiceProvider = Provider<ResumeService>((ref) {
  return ResumeService();
});

final educationServiceProvider = Provider<EducationService>((ref) {
  return EducationService();
});

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final apiClient = APIClient();
  return SubscriptionService(apiClient);
});

final resumeProvider = StateNotifierProvider<ResumeNotifier, ResumeState>((
  ref,
) {
  final resumeService = ref.watch(resumeServiceProvider);
  final educationService = ref.watch(educationServiceProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return ResumeNotifier(resumeService, educationService, subscriptionService);
});
