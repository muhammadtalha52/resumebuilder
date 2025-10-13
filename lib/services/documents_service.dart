import 'package:dio/dio.dart';
import 'package:skillresy/main.dart';
import '../models/documents_response.dart';
import '../utils/endpoint_headers.dart';

class DocumentsService {
  Future<DocumentsResponse> getFolderItems({required int folderId}) async {
    try {
      final response = await apiClient.dio.get(
        ApiEndpoints.folderItems,
        queryParameters: {'folder': folderId},
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return DocumentsResponse.fromJson(response.data);
      } else {
        throw Exception(
          response.data?['message'] ?? 'Failed to fetch documents',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to fetch documents';

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
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch documents: $e');
    }
  }

  /// Save folder item after S3 upload
  Future<Data> saveFolderItem({
    required int folderId,
    required String name,
    required String s3Filename,
    required String fileType,
    required int fileSize,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final requestBody = {
        'folder': folderId,
        'name': name,
        's3_filename': s3Filename,
        'file_type': fileType,
        'file_size': fileSize,
        if (description != null) 'description': description,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await apiClient.dio.post(
        ApiEndpoints.folderItems,
        data: requestBody,
        options: Options(
          headers: {
            WAInterceptorHeaders.requiresToken: true,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Data.fromJson(response.data);
      } else {
        throw Exception('Failed to save document');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to save document';

        if (responseData is Map) {
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          } else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          } else if (responseData.containsKey('detail')) {
            errorMessage = responseData['detail'].toString();
          }
        }

        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to save document: $e');
    }
  }
}
