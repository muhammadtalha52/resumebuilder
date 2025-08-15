import 'package:dio/dio.dart';
import '../models/update_profile_model.dart';
import '../utils/endpoint_headers.dart';
import 'api_client.dart';

class ProfileService {
  final APIClient _apiClient = APIClient();

  /// Updates profile image with S3 filename
  Future<UpdateProfileModel> updateProfileImage(String s3FileName) async {
    return updateProfile({'profile_image': s3FileName});
  }

  Future<UpdateProfileModel> updateProfile(
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.profileUpdate,
        data: updateData,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return UpdateProfileModel.fromJson(response.data);
      } else {
        throw Exception(response.data?['error'] ?? 'Failed to update profile');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Profile update failed';

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
          errorMessage = 'Unauthorized: $errorMessage';
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
      throw Exception('Profile update failed: $e');
    }
  }
}
