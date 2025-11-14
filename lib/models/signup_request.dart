import '../providers/onboarding_provider.dart';
import '../utils/date_helpers.dart';

class WorkExperience {
  final String jobTitle;
  final String companyName;
  final String workStartDate;
  final String? workEndDate;
  final List<String> keyResponsibilities;
  final bool isCurrentJob;

  WorkExperience({
    required this.jobTitle,
    required this.companyName,
    required this.workStartDate,
    this.workEndDate,
    required this.keyResponsibilities,
    required this.isCurrentJob,
  });

  Map<String, dynamic> toJson() {
    return {
      'job_title': jobTitle,
      'company_name': companyName,
      'work_start_date': workStartDate,
      'work_end_date': workEndDate,
      'key_responsibilities': keyResponsibilities,
      'is_current_job': isCurrentJob,
    };
  }
}

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
  final String? hometown;
  final String? professionalSummary;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? portfolioUrl;
  final List<String>? desiredJobTitles;
  final List<String>? industryPreferences;
  final List<String>? longTermCareerGoals;
  final int? degreeType;
  final int? major;
  final String? institution;
  final String? graduationDate;
  final List<int>? certificationsTraining;
  final List<WorkExperience>? workExperience;
  final List<String>? hardSkills;
  final List<String>? softSkills;
  final List<String>? toolsTechnologies;
  final List<String>? languages;
  final List<String>? volunteerWork;
  final List<String>? hobbiesInterests;
  final String? references;
  final int? role;
  final String? resumeFileName;
  final int? desiredPayRange;
  final List<String>? locationPreferences;

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
    this.hometown,
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
    this.workExperience,
    this.hardSkills,
    this.softSkills,
    this.toolsTechnologies,
    this.languages,
    this.volunteerWork,
    this.hobbiesInterests,
    this.references,
    this.role,
    this.resumeFileName,
    this.desiredPayRange,
    this.locationPreferences,
  });

  factory SignUpRequest.fromOnboardingState(OnboardingState state) {
    // Extract names from fullName
    final nameParts = (state.fullName ?? '').split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Extract career goals data
    final careerGoals = state.careerGoals;
    final desiredJobTitles = careerGoals?['jobTitles'] != null
        ? (careerGoals!['jobTitles'] as List<dynamic>).cast<String>()
        : null;
    final industryPreferences = careerGoals?['industries'] != null
        ? (careerGoals!['industries'] as List<dynamic>).cast<String>()
        : null;
    final longTermGoalsValue = careerGoals?['longTermGoals'] as String?;
    final longTermCareerGoals =
        longTermGoalsValue != null && longTermGoalsValue.isNotEmpty
        ? [longTermGoalsValue]
        : null;

    // Extract education data with IDs
    final education = state.education;
    // Ensure graduation date is in correct format (yyyy-MM-dd)
    final graduationDate = DateHelpers.convertToApiDateFormat(
      education?['graduationDate'] as String?,
    );
    final degreeTypeId = education?['degreeTypeId'] as int?;
    final majorId = education?['majorId'] as int?;
    final institution = education?['institution'] as String?;
    final certificationIds = education?['certificationIds'] != null
        ? (education!['certificationIds'] as List<dynamic>).cast<int>()
        : null;

    // Extract work experience data
    final workExp = state.workExperience;
    final experiences = workExp?['experiences'] as List<dynamic>?;
    List<WorkExperience>? workExperienceList;

    if (experiences != null && experiences.isNotEmpty) {
      workExperienceList = [];

      for (final exp in experiences) {
        final expMap = exp as Map<String, dynamic>;

        // Extract data for each experience
        final jobTitle = expMap['jobTitle'] as String? ?? '';
        final companyName = expMap['company'] as String? ?? '';
        final startDate =
            DateHelpers.convertToApiDateFormat(
              expMap['startDate'] as String?,
            ) ??
            '';
        final endDate = expMap['currentJob'] == true
            ? null
            : DateHelpers.convertToApiDateFormat(expMap['endDate'] as String?);
        final responsibilities = expMap['responsibilities'] as String? ?? '';
        final isCurrentJob = expMap['currentJob'] as bool? ?? false;

        // Split responsibilities by common delimiters if it's a single string
        List<String> responsibilitiesList = [];
        if (responsibilities.isNotEmpty) {
          // Try to split by common delimiters
          if (responsibilities.contains('\n')) {
            responsibilitiesList = responsibilities
                .split('\n')
                .map((r) => r.trim())
                .where((r) => r.isNotEmpty)
                .toList();
          } else if (responsibilities.contains(';')) {
            responsibilitiesList = responsibilities
                .split(';')
                .map((r) => r.trim())
                .where((r) => r.isNotEmpty)
                .toList();
          } else if (responsibilities.contains(',')) {
            responsibilitiesList = responsibilities
                .split(',')
                .map((r) => r.trim())
                .where((r) => r.isNotEmpty)
                .toList();
          } else {
            responsibilitiesList = [responsibilities];
          }
        }

        if (jobTitle.isNotEmpty &&
            companyName.isNotEmpty &&
            startDate.isNotEmpty) {
          workExperienceList.add(
            WorkExperience(
              jobTitle: jobTitle,
              companyName: companyName,
              workStartDate: startDate,
              workEndDate: endDate,
              keyResponsibilities: responsibilitiesList,
              isCurrentJob: isCurrentJob,
            ),
          );
        }
      }

      if (workExperienceList.isEmpty) {
        workExperienceList = null;
      }
    }

    // Extract skills data
    final skills = state.skills;
    final hardSkills = skills?['hardSkills'] != null
        ? (skills!['hardSkills'] as List<dynamic>).cast<String>()
        : null;
    final softSkills = skills?['softSkills'] != null
        ? (skills!['softSkills'] as List<dynamic>).cast<String>()
        : null;
    final toolsTechnologies = skills?['tools'] != null
        ? (skills!['tools'] as List<dynamic>).cast<String>()
        : null;

    // Extract optional info
    final optionalInfo = state.optionalInfo;
    final languages = optionalInfo?['languages'] != null
        ? (optionalInfo!['languages'] as List<dynamic>).cast<String>()
        : null;
    final volunteerWork = optionalInfo?['volunteerWork'] != null
        ? (optionalInfo!['volunteerWork'] as List<dynamic>).cast<String>()
        : null;
    final hobbiesInterests = optionalInfo?['hobbies'] != null
        ? (optionalInfo!['hobbies'] as List<dynamic>).cast<String>()
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
      address: '',
      city: '',
      userState: '',
      country: '',
      postalCode: '',
      hometown: state.hometown,
      // Optional fields
      linkedinUrl: state.linkedIn,
      portfolioUrl: state.website,
      desiredJobTitles: desiredJobTitles,
      industryPreferences: industryPreferences,
      longTermCareerGoals: longTermCareerGoals,
      degreeType: degreeTypeId,
      major: majorId,
      institution: institution,
      graduationDate: graduationDate,
      certificationsTraining: certificationIds,
      workExperience: workExperienceList,
      hardSkills: hardSkills,
      softSkills: softSkills,
      toolsTechnologies: toolsTechnologies,
      languages: languages,
      volunteerWork: volunteerWork,
      hobbiesInterests: hobbiesInterests,
      references: references,
      role: _getRoleId(state.selectedRole),
      resumeFileName: null,
      // Not collected in onboarding
      desiredPayRange: null,
      // Extract location preferences from career goals
      locationPreferences: careerGoals?['locationPreferences'] != null
          ? (careerGoals!['locationPreferences'] as List<dynamic>)
                .cast<String>()
          : null,
    );
  }

  // Helper method to map role string to ID
  static int _getRoleId(String? role) {
    switch (role?.toLowerCase()) {
      case 'candidate':
        return 1;
      case 'student':
        return 2;
      case 'recruiter':
        return 3;
      default:
        return 1; // Default to student
    }
  }
}
