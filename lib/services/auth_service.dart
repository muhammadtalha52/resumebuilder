import 'package:dio/dio.dart';
import '../models/login_model.dart';
import '../models/signup_request.dart';
import '../models/student_signup_request.dart';
import '../utils/endpoint_headers.dart';
import 'api_client.dart';

class AuthService {
  final APIClient _apiClient = APIClient();

  Future<LoginModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
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
        final responseData = e.response!.data;
        String errorMessage = 'Login failed';

        // Handle different error response formats
        if (responseData is Map) {
          // Check for 'error' field
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          }
          // Check for 'message' field
          else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          }
          // Check for 'errors' field (validation errors)
          else if (responseData.containsKey('errors')) {
            final errors = responseData['errors'];
            if (errors is Map) {
              // Collect all validation errors
              final errorMessages = <String>[];
              errors.forEach((field, messages) {
                if (messages is List) {
                  errorMessages.addAll(messages.map((m) => m.toString()));
                } else {
                  errorMessages.add(messages.toString());
                }
              });
              errorMessage = errorMessages.join('\n');
            } else if (errors is List) {
              errorMessage = errors.join('\n');
            } else {
              errorMessage = errors.toString();
            }
          }
          // Check for 'detail' field (common in some APIs)
          else if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          }
          // If none of the above, try to extract any meaningful message
          else {
            errorMessage = responseData.toString();
          }
        } else if (responseData is String) {
          errorMessage = responseData;
        }

        // Add status code information for better debugging
        if (e.response!.statusCode == 401) {
          errorMessage = 'Invalid credentials: $errorMessage';
        } else if (e.response!.statusCode == 422) {
          errorMessage = 'Validation Error: $errorMessage';
        } else if (e.response!.statusCode == 400) {
          errorMessage = 'Bad Request: $errorMessage';
        }

        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      // Only wrap in Exception if it's not already an Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Login failed: $e');
    }
  }

  /// Check if email is available to create an account
  /// Returns true if email is available (not registered yet)
  /// Returns false if email already exists in the system
  Future<bool> checkEmailAvailable(String email) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.isEmailExists,
        queryParameters: {'email': email.toLowerCase()},
      );

      // API returns 200 success when email is available to create an account
      if (response.statusCode == 200) {
        return true; // Email is available
      }
      return false; // Email already exists
    } on DioException catch (e) {
      // If API returns error, it might mean email already exists
      // Return false to indicate email is not available
      print('Error checking email availability: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error checking email: $e');
      return false;
    }
  }

  Future<LoginModel> register(SignUpRequest request) async {
    try {
      var requestData = {
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
        if (request.portfolioUrl != null) 'portfolio_url': request.portfolioUrl,
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
        if (request.workExperience != null)
          'work_experience': request.workExperience!
              .map((exp) => exp.toJson())
              .toList(),
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
        if (request.resumeFileName != null)
          'resume_file_name': request.resumeFileName,
        if (request.desiredPayRange != null)
          'desired_pay_range': request.desiredPayRange,
        if (request.locationPreferences != null)
          'location_preferences': request.locationPreferences,
      };

      print(requestData);

      final response = await _apiClient.dio.post(
        ApiEndpoints.register,
        data: requestData,
      );

      if (response.statusCode == 201 && response.data != null) {
        return LoginModel.fromJson(response.data);
      } else {
        throw Exception(response.data?['error'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Registration failed';

        // Handle different error response formats
        if (responseData is Map) {
          // Check for 'error' field
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          }
          // Check for 'message' field
          else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          }
          // Check for 'errors' field (validation errors)
          else if (responseData.containsKey('errors')) {
            final errors = responseData['errors'];
            if (errors is Map) {
              // Collect all validation errors
              final errorMessages = <String>[];
              errors.forEach((field, messages) {
                if (messages is List) {
                  errorMessages.addAll(messages.map((m) => m.toString()));
                } else {
                  errorMessages.add(messages.toString());
                }
              });
              errorMessage = errorMessages.join('\n');
            } else if (errors is List) {
              errorMessage = errors.join('\n');
            } else {
              errorMessage = errors.toString();
            }
          }
          // Check for 'detail' field (common in some APIs)
          else if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          }
          // If none of the above, try to extract any meaningful message
          else {
            errorMessage = responseData.toString();
          }
        } else if (responseData is String) {
          errorMessage = responseData;
        }

        // Add status code information for better debugging
        if (e.response!.statusCode == 422) {
          errorMessage = 'Validation Error: $errorMessage';
        } else if (e.response!.statusCode == 400) {
          errorMessage = 'Bad Request: $errorMessage';
        } else if (e.response!.statusCode == 409) {
          errorMessage = 'Conflict: $errorMessage';
        }

        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      // Only wrap in Exception if it's not already an Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Registration failed: $e');
    }
  }

  Future<LoginModel> registerStudent(StudentSignupRequest request) async {
    try {
      final requestData = request.toJson();

      print('Student Registration Data: $requestData');

      final response = await _apiClient.dio.post(
        ApiEndpoints.register,
        data: requestData,
      );

      if (response.statusCode == 201 && response.data != null) {
        return LoginModel.fromJson(response.data);
      } else {
        throw Exception(response.data?['error'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Registration failed';

        // Handle different error response formats
        if (responseData is Map) {
          // Check for 'error' field
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          }
          // Check for 'message' field
          else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          }
          // Check for 'errors' field (validation errors)
          else if (responseData.containsKey('errors')) {
            final errors = responseData['errors'];
            if (errors is Map) {
              // Collect all validation errors
              final errorMessages = <String>[];
              errors.forEach((field, messages) {
                if (messages is List) {
                  errorMessages.addAll(messages.map((m) => m.toString()));
                } else {
                  errorMessages.add(messages.toString());
                }
              });
              errorMessage = errorMessages.join('\n');
            } else if (errors is List) {
              errorMessage = errors.join('\n');
            } else {
              errorMessage = errors.toString();
            }
          }
          // Check for 'detail' field (common in some APIs)
          else if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          }
          // If none of the above, try to extract any meaningful message
          else {
            errorMessage = responseData.toString();
          }
        } else if (responseData is String) {
          errorMessage = responseData;
        }

        // Add status code information for better debugging
        if (e.response!.statusCode == 422) {
          errorMessage = 'Validation Error: $errorMessage';
        } else if (e.response!.statusCode == 400) {
          errorMessage = 'Bad Request: $errorMessage';
        } else if (e.response!.statusCode == 409) {
          errorMessage = 'Conflict: $errorMessage';
        }

        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      // Only wrap in Exception if it's not already an Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Registration failed: $e');
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      } else {
        throw Exception(
          response.data?['message'] ?? 'Failed to send reset email',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to send reset email';

        // Handle different error response formats
        if (responseData is Map) {
          // Check for 'error' field
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          }
          // Check for 'message' field
          else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          }
          // Check for 'errors' field (validation errors)
          else if (responseData.containsKey('errors')) {
            final errors = responseData['errors'];
            if (errors is Map) {
              // Collect all validation errors
              final errorMessages = <String>[];
              errors.forEach((field, messages) {
                if (messages is List) {
                  errorMessages.addAll(messages.map((m) => m.toString()));
                } else {
                  errorMessages.add(messages.toString());
                }
              });
              errorMessage = errorMessages.join('\n');
            } else if (errors is List) {
              errorMessage = errors.join('\n');
            } else {
              errorMessage = errors.toString();
            }
          }
          // Check for 'detail' field (common in some APIs)
          else if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          }
          // If none of the above, try to extract any meaningful message
          else {
            errorMessage = responseData.toString();
          }
        } else if (responseData is String) {
          errorMessage = responseData;
        }

        // Add status code information for better debugging
        if (e.response!.statusCode == 404) {
          errorMessage = 'Email not found: $errorMessage';
        } else if (e.response!.statusCode == 400) {
          errorMessage = 'Bad Request: $errorMessage';
        }

        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      // Only wrap in Exception if it's not already an Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to send reset email: $e');
    }
  }

  Future<void> deleteAccount({required int userId}) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiEndpoints.deleteAccount}$userId/',
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Account deleted successfully
        return;
      } else {
        throw Exception(response.data?['error'] ?? 'Failed to delete account');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to delete account';

        // Handle different error response formats
        if (responseData is Map) {
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          } else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          } else if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          } else {
            errorMessage = responseData.toString();
          }
        } else if (responseData is String) {
          errorMessage = responseData;
        }

        // Add status code information
        if (e.response!.statusCode == 404) {
          errorMessage = 'Account not found: $errorMessage';
        } else if (e.response!.statusCode == 403) {
          errorMessage = 'Access denied: $errorMessage';
        } else if (e.response!.statusCode == 401) {
          errorMessage = 'Unauthorized: $errorMessage';
        }

        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to delete account: $e');
    }
  }
}
