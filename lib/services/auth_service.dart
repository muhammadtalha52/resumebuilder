import 'package:dio/dio.dart';
import '../models/login_model.dart';
import '../models/signup_request.dart';
import '../utils/endpoint_headers.dart';
import 'api_client.dart';

class AuthService {
  final APIClient _apiClient = APIClient();

  Future<LoginModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dioClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        return LoginModel.fromJson(response.data);
      } else {
        throw Exception(response.data?['error'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Login failed');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<LoginModel> register(SignUpRequest request) async {
    try {
      final response = await _apiClient.dioClient.post(
        ApiEndpoints.register,
        data: {
          'email': request.email,
          'password': request.password,
          'confirm_password': request.confirmPassword,
          'full_name': request.fullName,
          'first_name': request.firstName,
          'last_name': request.lastName,
          'phone_number': request.phoneNumber,
          'date_of_birth': request.dateOfBirth,
          'address': request.address,
          'city': request.city,
          'state': request.userState,
          'country': request.country,
          'postal_code': request.postalCode,
          if (request.professionalSummary != null)
            'professional_summary': request.professionalSummary,
          if (request.linkedinUrl != null) 'linkedin_url': request.linkedinUrl,
          if (request.githubUrl != null) 'github_url': request.githubUrl,
          if (request.portfolioUrl != null)
            'portfolio_url': request.portfolioUrl,
          if (request.desiredJobTitles != null)
            'desired_job_titles': request.desiredJobTitles,
          if (request.industryPreferences != null)
            'industry_preferences': request.industryPreferences,
          if (request.longTermCareerGoals != null)
            'long_term_career_goals': request.longTermCareerGoals,
          if (request.degreeType != null) 'degree_type': request.degreeType,
          if (request.major != null) 'major': request.major,
          if (request.institution != null) 'institution': request.institution,
          if (request.graduationDate != null)
            'graduation_date': request.graduationDate,
          if (request.certificationsTraining != null)
            'certifications_training': request.certificationsTraining,
          if (request.jobTitles != null) 'job_titles': request.jobTitles,
          if (request.companyNames != null)
            'company_names': request.companyNames,
          if (request.workDuration != null)
            'work_duration': request.workDuration,
          if (request.keyResponsibilities != null)
            'key_responsibilities': request.keyResponsibilities,
          if (request.hardSkills != null) 'hard_skills': request.hardSkills,
          if (request.softSkills != null) 'soft_skills': request.softSkills,
          if (request.toolsTechnologies != null)
            'tools_technologies': request.toolsTechnologies,
          if (request.languages != null) 'languages': request.languages,
          if (request.volunteerWork != null)
            'volunteer_work': request.volunteerWork,
          if (request.hobbiesInterests != null)
            'hobbies_interests': request.hobbiesInterests,
          if (request.references != null) 'references': request.references,
          if (request.role != null) 'role': request.role,
          if (request.resumeUrl != null) 'resume_url': request.resumeUrl,
          if (request.workStartDate != null)
            'work_start_date': request.workStartDate,
          if (request.workEndDate != null) 'work_end_date': request.workEndDate,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        return LoginModel.fromJson(response.data);
      } else {
        throw Exception(response.data?['error'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['error'] ?? 'Registration failed');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
}
