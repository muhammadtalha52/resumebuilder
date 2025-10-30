import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/date_helpers.dart';
import '../models/resume_parse_model.dart';

class OnboardingState {
  final int currentStep;
  final String? selectedRole;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? linkedIn;
  final String? website;
  final String? password;
  final bool acceptedTerms;
  final Map<String, dynamic>? careerGoals;
  final Map<String, dynamic>? education;
  final Map<String, dynamic>? workExperience;
  final Map<String, dynamic>? skills;
  final Map<String, dynamic>? optionalInfo;
  final ResumeParse? parsedResume;

  OnboardingState({
    this.currentStep = 1,
    this.selectedRole,
    this.fullName,
    this.email,
    this.phone,
    this.linkedIn,
    this.website,
    this.password,
    this.acceptedTerms = false,
    this.careerGoals,
    this.education,
    this.workExperience,
    this.skills,
    this.optionalInfo,
    this.parsedResume,
  });

  OnboardingState copyWith({
    int? currentStep,
    String? selectedRole,
    String? fullName,
    String? email,
    String? phone,
    String? linkedIn,
    String? website,
    String? password,
    bool? acceptedTerms,
    Map<String, dynamic>? careerGoals,
    Map<String, dynamic>? education,
    Map<String, dynamic>? workExperience,
    Map<String, dynamic>? skills,
    Map<String, dynamic>? optionalInfo,
    ResumeParse? parsedResume,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      selectedRole: selectedRole ?? this.selectedRole,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      linkedIn: linkedIn ?? this.linkedIn,
      website: website ?? this.website,
      password: password ?? this.password,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      careerGoals: careerGoals ?? this.careerGoals,
      education: education ?? this.education,
      workExperience: workExperience ?? this.workExperience,
      skills: skills ?? this.skills,
      optionalInfo: optionalInfo ?? this.optionalInfo,
      parsedResume: parsedResume ?? this.parsedResume,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState());

  void setRole(String role) {
    state = state.copyWith(selectedRole: role);
  }

  void updatePersonalDetails({
    required String fullName,
    required String email,
    required String phone,
    String? linkedIn,
    String? website,
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      phone: phone,
      linkedIn: linkedIn,
      website: website,
    );
  }

  void setUserDetails({
    required String fullName,
    required String email,
    required String password,
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      password: password,
    );
  }

  void toggleTermsAcceptance(bool value) {
    state = state.copyWith(acceptedTerms: value);
  }

  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void updateCareerGoals(Map<String, dynamic> goals) {
    state = state.copyWith(careerGoals: goals);
  }

  void updateEducation({
    String? degreeType,
    int? degreeTypeId,
    String? major,
    int? majorId,
    String? institution,
    int? institutionId,
    DateTime? graduationDate,
    bool? degreeNotCompleted,
    List<String>? certifications,
    List<int>? certificationIds,
  }) {
    final educationData = {
      'degreeType': degreeType,
      'degreeTypeId': degreeTypeId,
      'major': major,
      'majorId': majorId,
      'institution': institution,
      'institutionId': institutionId,
      'graduationDate': DateHelpers.formatToApiDate(graduationDate),
      'degreeNotCompleted': degreeNotCompleted ?? false,
      'certifications': certifications ?? [],
      'certificationIds': certificationIds ?? [],
    };
    state = state.copyWith(education: educationData);
  }

  void updateWorkExperience(Map<String, dynamic> workExperience) {
    state = state.copyWith(workExperience: workExperience);
  }

  void updateSkills(Map<String, dynamic> skills) {
    state = state.copyWith(skills: skills);
  }

  void updateOptionalInfo(Map<String, dynamic> optionalInfo) {
    state = state.copyWith(optionalInfo: optionalInfo);
  }

  /// Store parsed resume data and auto-populate onboarding fields
  void storeParsedResumeData(ResumeParse resumeData) {
    // Store the raw parsed data for later use in Steps 4-6
    // This method is called from Step 4, so we should NOT overwrite
    // any user data from Steps 1-3 (personal details, education)
    state = state.copyWith(parsedResume: resumeData);

    // Note: We intentionally do NOT auto-populate personal details (Step 1)
    // or education (Step 3) here, as the user has already completed those steps
    // and we don't want to overwrite their manually entered data.

    // The parsed resume data will be used by:
    // - Step 4: Work experience (handled manually in the step)
    // - Step 5: Skills (auto-populated from parsedResumeData)
    // - Step 6: Optional info (reference only)
  }

  /// Get parsed resume data for use in other steps
  ResumeParse? get parsedResumeData => state.parsedResume;

  /// Populate onboarding data from parsed resume (used by resume review screen)
  void populateFromParsedResume(ResumeParse resumeData) {
    // Store the parsed data first
    state = state.copyWith(parsedResume: resumeData);

    // Populate personal details if available (use Personal object from ResumeParse)
    if (resumeData.personal != null) {
      final personal = resumeData.personal!;
      state = state.copyWith(
        fullName: personal.name?.isNotEmpty == true
            ? personal.name
            : state.fullName,
        email: personal.email?.isNotEmpty == true
            ? personal.email
            : state.email,
        phone: personal.phone?.isNotEmpty == true
            ? personal.phone
            : state.phone,
        linkedIn: personal.linkedin?.isNotEmpty == true
            ? personal.linkedin
            : state.linkedIn,
        website: personal.personalWebsite?.isNotEmpty == true
            ? personal.personalWebsite
            : state.website,
      );
    }

    // Populate career goals if available
    if (resumeData.workExperience.isNotEmpty) {
      // Extract job titles from work experience
      final jobTitles = resumeData.workExperience
          .map((exp) => exp.role)
          .where((title) => title != null && title.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      // Extract industries from work experience companies
      final industries = resumeData.workExperience
          .map((exp) => exp.company)
          .where((company) => company != null && company.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      state = state.copyWith(
        careerGoals: {
          ...?state.careerGoals,
          'jobTitles': jobTitles,
          'industries': industries,
        },
      );
    }

    // Populate work experience if available
    if (resumeData.workExperience.isNotEmpty) {
      final workExperiences = resumeData.workExperience.map((exp) {
        return {
          'jobTitle': exp.role ?? '',
          'company': exp.company ?? '',
          'startDate': exp.parsedFromDate?.toIso8601String(),
          'endDate': exp.parsedToDate?.toIso8601String(),
          'responsibilities': exp.description.join('\n'),
          'currentJob': exp.isCurrent,
        };
      }).toList();

      state = state.copyWith(workExperience: {'experiences': workExperiences});
    }

    // Populate skills if available (use Skills object structure)
    if (resumeData.skills != null) {
      final skills = resumeData.skills!;
      state = state.copyWith(
        skills: {
          'hardSkills': List<String>.from(skills.hardSkills),
          'softSkills': List<String>.from(skills.softSkills),
          'tools': List<String>.from(skills.toolsAndTechnologies),
        },
      );
    }

    // Populate education if available (existing data takes precedence)
    if (resumeData.education.isNotEmpty && state.education == null) {
      final education = resumeData.education.first;
      state = state.copyWith(
        education: {
          'degreeType': education.degreeType,
          'major': education.major,
          'institution': education.university,
          'graduationDate': education.toDate,
          'degreeNotCompleted': false,
        },
      );
    }

    // Populate optional info if available
    if (resumeData.optionalInfo != null) {
      final optionalInfo = resumeData.optionalInfo!;
      final existingOptionalInfo = Map<String, dynamic>.from(
        state.optionalInfo ?? {},
      );

      // Add languages if available
      if (optionalInfo.languages.isNotEmpty) {
        existingOptionalInfo['languages'] = List<String>.from(
          optionalInfo.languages,
        );
      }

      // Add hobbies if available
      if (optionalInfo.hobbiesAndInterests?.isNotEmpty == true) {
        existingOptionalInfo['hobbies'] = optionalInfo.hobbiesAndInterests;
      }

      state = state.copyWith(optionalInfo: existingOptionalInfo);
    }
  }

  void reset() {
    state = OnboardingState();
  }

  /// Clear only parsed resume data while preserving user-entered data
  void clearParsedResumeData() {
    state = state.copyWith(parsedResume: null);
  }

  Future<void> completeOnboarding() async {
    // TODO: Implement API call to create account
    // For now, just simulate a delay
    await Future.delayed(const Duration(seconds: 2));
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier();
    });
