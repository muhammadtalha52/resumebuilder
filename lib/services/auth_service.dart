import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/login_model.dart';
import '../models/signup_request.dart';
import '../models/student_signup_request.dart';
import '../utils/endpoint_headers.dart';
import 'analytics_service.dart';
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
        data: {'email': email, 'password': password, 'platform': 'app'},
      );

      if (response.statusCode == 200 && response.data != null) {
        return LoginModel.fromJson(response.data);
      } else {
        String errMsg = 'Login failed';
        if (response.data is Map) {
          errMsg = response.data?['error'] ?? 
                   response.data?['message'] ?? 
                   response.data?['detail'] ?? 
                   'Login failed';
        } else if (response.data is String) {
          errMsg = response.data;
        }
        throw Exception(errMsg);
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
        } else if (e.response!.statusCode == 403) {
          // Pass the exact suspension/deactivation message from the server
          errorMessage = errorMessage;
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
      debugPrint('Error checking email availability: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error checking email: $e');
      return false;
    }
  }

  Future<LoginModel> register(SignUpRequest request) async {
    try {
      var requestData = {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'email': request.email,
        'password': request.password,
        'confirm_password': request.confirmPassword,
        'full_name': request.fullName,
        'first_name': request.firstName,
        'last_name': request.lastName,
        'phone_number': request.phoneNumber,
        if (request.dateOfBirth != null) 'date_of_birth': request.dateOfBirth,
        'address': request.address,
        'city': request.city,
        'state': request.userState,
        'country': request.country,
        'postal_code': request.postalCode,
        if (request.hometown != null) 'home_town': request.hometown,
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

      debugPrint("==============================");
      debugPrint("API URL: ${_apiClient.dio.options.baseUrl}${ApiEndpoints.register}");
      debugPrint("Headers: ${_apiClient.dio.options.headers}");
      debugPrint("Body: $requestData");

      final response = await _apiClient.dio.post(
        ApiEndpoints.register,
        data: requestData,
      );
      
      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Response Data: ${response.data}");
      debugPrint("==============================");

      if (response.statusCode == 201 && response.data != null) {
        // Log successful signup to Firebase Analytics for Google Ads tracking
        // Note: The 'source' parameter will be tracked even if not configured as a custom dimension in GA4.
        try {
          await FirebaseAnalytics.instance.logEvent(
            name: 'ads_conversion_signup',
            parameters: {
              'signup_source': 'mobile_app',
            },
          );
          debugPrint("🔥 FIREBASE EVENT TRIGGERED: ads_conversion_signup with params: {signup_source: mobile_app}");
          await AnalyticsService.logRegistration('candidate');
        } catch (e) {
          debugPrint('🔥 Firebase Analytics error: $e');
        }
        return LoginModel.fromJson(response.data);
      } else {
        throw Exception(response.data?['error'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      debugPrint("Exception Occurred: ${e.message}");
      debugPrint("Exception Response Status: ${e.response?.statusCode}");
      debugPrint("Exception Response Data: ${e.response?.data}");
      debugPrint("==============================");
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
      requestData['platform'] = Platform.isIOS ? 'ios' : 'android';

      debugPrint("==============================");
      debugPrint("API URL: ${_apiClient.dio.options.baseUrl}${ApiEndpoints.register}");
      debugPrint("Headers: ${_apiClient.dio.options.headers}");
      debugPrint("Body: $requestData");

      final response = await _apiClient.dio.post(
        ApiEndpoints.register,
        data: requestData,
      );
      
      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Response Data: ${response.data}");
      debugPrint("==============================");

      if (response.statusCode == 201 && response.data != null) {
        // Log successful signup to Firebase Analytics for Google Ads tracking
        // Note: The 'source' parameter will be tracked even if not configured as a custom dimension in GA4.
        try {
          await FirebaseAnalytics.instance.logEvent(
            name: 'ads_conversion_signup',
            parameters: {
              'signup_source': 'mobile_app',
            },
          );
          debugPrint("🔥 FIREBASE EVENT TRIGGERED: ads_conversion_signup with params: {signup_source: mobile_app}");
          await AnalyticsService.logRegistration('student');
        } catch (e) {
          debugPrint('🔥 Firebase Analytics error: $e');
        }
        return LoginModel.fromJson(response.data);
      } else {
        throw Exception(response.data?['error'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      debugPrint("Exception Occurred: ${e.message}");
      debugPrint("Exception Response Status: ${e.response?.statusCode}");
      debugPrint("Exception Response Data: ${e.response?.data}");
      debugPrint("==============================");
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

  Future<LoginModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required int role,
    String? heardAboutUs,
  }) async {
    try {
      final requestData = {
        'email': email,
        'password': password,
        'role': role,
        'platform': Platform.isIOS ? 'ios' : 'android',
        if (heardAboutUs != null && heardAboutUs.isNotEmpty) 'heard_about_us': heardAboutUs,
      };

      debugPrint("==============================");
      debugPrint("API URL: ${_apiClient.dio.options.baseUrl}${ApiEndpoints.registerSimple}");
      debugPrint("Headers: ${_apiClient.dio.options.headers}");
      debugPrint("Body: $requestData");

      final response = await _apiClient.dio.post(
        ApiEndpoints.registerSimple,
        data: requestData,
      );
      
      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Response Data: ${response.data}");
      debugPrint("==============================");

      if (response.statusCode == 201 && response.data != null) {
        // Log successful signup to Firebase Analytics for Google Ads tracking
        // Note: The 'source' parameter will be tracked even if not configured as a custom dimension in GA4.
        try {
          await FirebaseAnalytics.instance.logEvent(
            name: 'ads_conversion_signup',
            parameters: {
              'signup_source': 'mobile_app',
            },
          );
          debugPrint("🔥 FIREBASE EVENT TRIGGERED: ads_conversion_signup with params: {signup_source: mobile_app}");
          
          // Role mapped to user type (1: candidate, 2: student)
          String userType = role == 2 ? 'student' : 'candidate';
          await AnalyticsService.logRegistration(userType);
        } catch (e) {
          debugPrint('🔥 Firebase Analytics error: $e');
        }
        return LoginModel.fromJson(response.data);
      } else {
        throw Exception(response.data?['error'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      debugPrint("Exception Occurred: ${e.message}");
      debugPrint("Exception Response Status: ${e.response?.statusCode}");
      debugPrint("Exception Response Data: ${e.response?.data}");
      debugPrint("==============================");
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Registration failed';

        if (responseData is Map) {
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          } else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          } else if (responseData.containsKey('errors')) {
            final errors = responseData['errors'];
            if (errors is Map) {
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
          } else if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          } else {
            errorMessage = responseData.toString();
          }
        } else if (responseData is String) {
          errorMessage = responseData;
        }

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

  Future<void> deleteAccount() async {
    try {
      final response = await _apiClient.dio.delete(
        ApiEndpoints.deleteAccount,
        data: {'confirm': 'DELETE'},
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Account deleted successfully
        return;
      } else {
        String errorMessage = 'Failed to delete account';
        if (response.data != null) {
          if (response.data is Map) {
            errorMessage = response.data['message']?.toString() ??
                response.data['error']?.toString() ??
                response.data['detail']?.toString() ??
                'Failed to delete account';
          } else if (response.data is String) {
            errorMessage = response.data;
          }
        }

        if (response.statusCode == 500) {
          errorMessage = "We couldn't delete your account, please try again.";
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          errorMessage = 'Session expired. Please log in again.';
        }

        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to delete account';

        // Handle different error response formats
        if (responseData is Map) {
          if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          } else if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          } else if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          } else {
            errorMessage = responseData.toString();
          }
        } else if (responseData is String) {
          errorMessage = responseData;
        }

        // Add status code information
        if (e.response!.statusCode == 500) {
          errorMessage = "We couldn't delete your account, please try again.";
        } else if (e.response!.statusCode == 404) {
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

  Future<Map<String, dynamic>> sendInviteEmail({required String email}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.sendInvite,
        data: {'invitee_email': email},
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(
          response.data?['error'] ??
              response.data?['message'] ??
              'Failed to send invitation',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to send invitation';

        if (responseData is Map) {
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          } else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          } else if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          }
        } else if (responseData is String) {
          errorMessage = responseData;
        }

        throw Exception(errorMessage);
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to send invitation');
    }
  }

  Future<Map<String, dynamic>> getInvites() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.getInvites,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to fetch invites');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to fetch invites';

        if (responseData is Map) {
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          } else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          } else if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          }
        } else if (responseData is String) {
          errorMessage = responseData;
        }

        throw Exception(errorMessage);
      }
      throw Exception('Network error. Please check your connection.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to fetch invites');
    }
  }
}
