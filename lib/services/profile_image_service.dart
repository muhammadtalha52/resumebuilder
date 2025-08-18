import 'dart:io';
import 'package:dio/dio.dart';
import '../utils/endpoint_headers.dart';
import 'api_client.dart';

class ProfileImageService {
  final APIClient _apiClient = APIClient();

  /// Uploads profile image to S3 and returns the S3 file name
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      // Create form data with the image file
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "profile_image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        ApiEndpoints.uploadProfilePhoto,
        data: formData,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 201 && response.data != null) {
        // Parse the new S3 response format
        final s3FileName = response.data['data']?['s3_file_name'];

        if (s3FileName != null) {
          return s3FileName;
        } else {
          throw Exception('No S3 file name returned from server');
        }
      } else {
        throw Exception(response.data?['error'] ?? 'Failed to upload image');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to upload image';

        // Handle different error response formats
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
            }
          }
        }

        // Add status code information for better debugging
        if (e.response!.statusCode == 413) {
          errorMessage = 'Image file too large: $errorMessage';
        } else if (e.response!.statusCode == 415) {
          errorMessage = 'Invalid image format: $errorMessage';
        }

        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to upload image: $e');
    }
  }
}
