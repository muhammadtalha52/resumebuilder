import '../providers/onboarding_provider.dart';
import '../utils/date_helpers.dart';

class SignUpRequest {
  final String email;
  final String password;
  final String confirmPassword;
  final String fullName;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String dateOfBirth;
  final String address;
  final String city;
  final String userState;
  final String country;
  final String postalCode;
  final String? professionalSummary;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? portfolioUrl;
  final String? desiredJobTitles;
  final String? industryPreferences;
  final String? longTermCareerGoals;
  final int? degreeType;
  final int? major;
  final int? institution;
  final String? graduationDate;
  final int? certificationsTraining;
  final String? jobTitles;
  final String? companyNames;
  final String? workDuration;
  final String? keyResponsibilities;
  final String? hardSkills;
  final String? softSkills;
  final String? toolsTechnologies;
  final String? languages;
  final String? volunteerWork;
  final String? hobbiesInterests;
  final String? references;
  final int? role;
  final String? resumeUrl;
  final String? workStartDate;
  final String? workEndDate;

  SignUpRequest({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.address,
    required this.city,
    required this.userState,
    required this.country,
    required this.postalCode,
    this.professionalSummary,
    this.linkedinUrl,
    this.githubUrl,
    this.portfolioUrl,
    this.desiredJobTitles,
    this.industryPreferences,
    this.longTermCareerGoals,
    this.degreeType,
    this.major,
    this.institution,
    this.graduationDate,
    this.certificationsTraining,
    this.jobTitles,
    this.companyNames,
    this.workDuration,
    this.keyResponsibilities,
    this.hardSkills,
    this.softSkills,
    this.toolsTechnologies,
    this.languages,
    this.volunteerWork,
    this.hobbiesInterests,
    this.references,
    this.role,
    this.resumeUrl,
    this.workStartDate,
    this.workEndDate,
  });

  factory SignUpRequest.fromOnboardingState(OnboardingState state) {
    // Extract names from fullName
    final nameParts = (state.fullName ?? '').split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Extract career goals data
    final careerGoals = state.careerGoals;
    final desiredJobTitles = careerGoals?['jobTitles'] != null
        ? (careerGoals!['jobTitles'] as List<dynamic>).join(', ')
        : null;
    final industryPreferences = careerGoals?['industries'] != null
        ? (careerGoals!['industries'] as List<dynamic>).join(', ')
        : null;
    final longTermCareerGoals = careerGoals?['longTermGoals'] as String?;

    // Extract education data with IDs
    final education = state.education;
    // Ensure graduation date is in correct format (yyyy-MM-dd)
    final graduationDate = DateHelpers.convertToApiDateFormat(
      education?['graduationDate'] as String?,
    );
    final degreeTypeId = education?['degreeTypeId'] as int?;
    final majorId = education?['majorId'] as int?;
    final institutionId = education?['institutionId'] as int?;
    final certificationId = education?['certificationId'] as int?;

    // Extract work experience data
    final workExp = state.workExperience;
    final experiences = workExp?['experiences'] as List<dynamic>?;

    String? jobTitles;
    String? companyNames;
    String? keyResponsibilities;
    String? workDuration;
    String? workStartDate;
    String? workEndDate;

    if (experiences != null && experiences.isNotEmpty) {
      final jobTitlesList = <String>[];
      final companyNamesList = <String>[];
      final responsibilitiesList = <String>[];

      for (final exp in experiences) {
        final expMap = exp as Map<String, dynamic>;
        if (expMap['jobTitle'] != null) jobTitlesList.add(expMap['jobTitle']);
        if (expMap['company'] != null) companyNamesList.add(expMap['company']);
        if (expMap['responsibilities'] != null) {
          responsibilitiesList.add(expMap['responsibilities']);
        }
      }

      jobTitles = jobTitlesList.isNotEmpty ? jobTitlesList.join(', ') : null;
      companyNames = companyNamesList.isNotEmpty
          ? companyNamesList.join(', ')
          : null;
      keyResponsibilities = responsibilitiesList.isNotEmpty
          ? responsibilitiesList.join(', ')
          : null;

      // Get start and end dates from first experience and format them
      if (experiences.isNotEmpty) {
        final firstExp = experiences.first as Map<String, dynamic>;
        workStartDate = DateHelpers.convertToApiDateFormat(
          firstExp['startDate'] as String?,
        );
        workEndDate = DateHelpers.convertToApiDateFormat(
          firstExp['endDate'] as String?,
        );
      }
    }

    // Extract skills data
    final skills = state.skills;
    final hardSkills = skills?['hardSkills'] != null
        ? (skills!['hardSkills'] as List<dynamic>).join(', ')
        : null;
    final softSkills = skills?['softSkills'] != null
        ? (skills!['softSkills'] as List<dynamic>).join(', ')
        : null;
    final toolsTechnologies = skills?['tools'] != null
        ? (skills!['tools'] as List<dynamic>).join(', ')
        : null;

    // Extract optional info
    final optionalInfo = state.optionalInfo;
    final languages = optionalInfo?['languages'] != null
        ? (optionalInfo!['languages'] as List<dynamic>).join(', ')
        : null;
    final volunteerWork = optionalInfo?['volunteerWork'] != null
        ? (optionalInfo!['volunteerWork'] as List<dynamic>).join(', ')
        : null;
    final hobbiesInterests = optionalInfo?['hobbies'] != null
        ? (optionalInfo!['hobbies'] as List<dynamic>).join(', ')
        : null;
    final references = optionalInfo?['references'] as String?;

    return SignUpRequest(
      email: state.email ?? '',
      password: state.password ?? '',
      confirmPassword: state.password ?? '',
      // Using same as password
      fullName: state.fullName ?? '',
      firstName: firstName,
      lastName: lastName,
      phoneNumber: state.phone ?? '',
      // Default values for required fields not collected in onboarding
      dateOfBirth: '1990-01-01',
      address: 'Not provided',
      city: 'Not provided',
      userState: 'Not provided',
      country: 'USA',
      postalCode: '00000',
      // Optional fields
      linkedinUrl: state.linkedIn,
      portfolioUrl: state.website,
      desiredJobTitles: desiredJobTitles,
      industryPreferences: industryPreferences,
      longTermCareerGoals: longTermCareerGoals,
      degreeType: degreeTypeId,
      major: majorId,
      institution: institutionId,
      graduationDate: graduationDate,
      certificationsTraining: certificationId,
      jobTitles: jobTitles,
      companyNames: companyNames,
      workDuration: workDuration,
      keyResponsibilities: keyResponsibilities,
      hardSkills: hardSkills,
      softSkills: softSkills,
      toolsTechnologies: toolsTechnologies,
      languages: languages,
      volunteerWork: volunteerWork,
      hobbiesInterests: hobbiesInterests,
      references: references,
      role: _getRoleId(state.selectedRole),
      resumeUrl: null,
      // Not collected in onboarding
      workStartDate: workStartDate,
      workEndDate: workEndDate,
    );
  }

  // Helper method to map role string to ID
  static int _getRoleId(String? role) {
    // TODO: Replace with actual role mapping
    // For now returning default value
    switch (role?.toLowerCase()) {
      case 'student':
        return 1;
      case 'professional':
        return 2;
      case 'freelancer':
        return 3;
      default:
        return 1; // Default to student
    }
  }
}
