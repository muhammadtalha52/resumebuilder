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
    String? certification,
    int? certificationId,
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
      'certification': certification,
      'certificationId': certificationId,
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

  void reset() {
    state = OnboardingState();
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
