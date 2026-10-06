import '../providers/student_signup_provider.dart';
import '../utils/date_helpers.dart';

class StudentSignupRequest {
  final String email;
  final String password;
  final String confirmPassword;
  final String fullName;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String hometown;
  final String school;
  final String expectedGraduationDate;
  final String major;
  final List<String> idealJobTitles;
  final int role;
  final String? heardAboutUs;

  StudentSignupRequest({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.hometown,
    required this.school,
    required this.expectedGraduationDate,
    required this.major,
    required this.idealJobTitles,
    required this.role,
    this.heardAboutUs,
  });

  factory StudentSignupRequest.fromStudentSignupState(
    StudentSignupState state,
  ) {
    // Extract names from fullName
    final nameParts = (state.fullName ?? '').split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Format graduation date
    final graduationDate = DateHelpers.formatToApiDate(
      state.expectedGraduationDate,
    );

    return StudentSignupRequest(
      email: state.email ?? '',
      password: state.password ?? '',
      confirmPassword: state.password ?? '',
      fullName: state.fullName ?? '',
      firstName: firstName,
      lastName: lastName,
      phoneNumber: state.phone ?? '',
      hometown: state.hometown ?? '',
      school: state.school ?? '',
      expectedGraduationDate: graduationDate ?? '',
      major: state.major ?? '',
      idealJobTitles: state.idealJobTitles,
      role: 2, // Student role ID
      heardAboutUs: state.heardAboutUs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'confirm_password': confirmPassword,
      'full_name': fullName,
      'phone_number': phoneNumber,
      if (idealJobTitles.isNotEmpty) 'ideal_job_titles': idealJobTitles,
      'home_town': hometown,
      'school_name': school,
      'school_major': major,
      'school_graduation_date': expectedGraduationDate,
      'role': role,
      if (heardAboutUs != null && heardAboutUs!.isNotEmpty) 'heard_about_us': heardAboutUs,
    };
  }
}
