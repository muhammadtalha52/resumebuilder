import 'package:dio/dio.dart';
import 'package:skillresy/main.dart';
import '../models/all_folders_response.dart';
import '../utils/endpoint_headers.dart';

class FolderService {
  Future<AllFoldersResponse> getAllFolders() async {
    try {
      final response = await apiClient.dio.get(
        ApiEndpoints.folders,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return AllFoldersResponse.fromJson(response.data);
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to fetch folders');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to fetch folders';

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
      throw Exception('Failed to fetch folders: $e');
    }
  }

  Future<ParentFolder> createFolder({
    required String name,
    String? description,
    int? parentId,
  }) async {
    try {
      final requestData = {
        'name': name,
        if (description != null) 'description': description,
        'parent': parentId,
      };

      final response = await apiClient.dio.post(
        ApiEndpoints.folders,
        data: requestData,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 201 && response.data != null) {
        final responseData = response.data;
        if (responseData['data'] != null) {
          return ParentFolder.fromJson(responseData['data']);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to create folder');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to create folder';

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
      throw Exception('Failed to create folder: $e');
    }
  }

  Future<ParentFolder> updateFolder({
    required int folderId,
    required String name,
    String? description,
  }) async {
    try {
      final requestData = {
        'name': name,
        if (description != null) 'description': description,
      };

      final response = await apiClient.dio.patch(
        '${ApiEndpoints.folders}$folderId/',
        data: requestData,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData['data'] != null) {
          return ParentFolder.fromJson(responseData['data']);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to update folder');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to update folder';

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
      throw Exception('Failed to update folder: $e');
    }
  }

  Future<void> deleteFolder({required int folderId}) async {
    try {
      final response = await apiClient.dio.delete(
        '${ApiEndpoints.folders}$folderId/',
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception(response.data?['message'] ?? 'Failed to delete folder');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to delete folder';

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
      throw Exception('Failed to delete folder: $e');
    }
  }

  Future<List<ParentFolder>> getSubfolders({required int parentId}) async {
    try {
      final response = await apiClient.dio.get(
        ApiEndpoints.folders,
        queryParameters: {'parent': parentId},
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData['data'] != null && responseData['data'] is List) {
          return (responseData['data'] as List)
              .map((json) => ParentFolder.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
          response.data?['message'] ?? 'Failed to fetch subfolders',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to fetch subfolders';

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
      throw Exception('Failed to fetch subfolders: $e');
    }
  }
}
