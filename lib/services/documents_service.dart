import 'package:dio/dio.dart';
import 'package:skillresy/main.dart';
import '../models/documents_response.dart' as doc;
import '../models/quiz_history_response.dart';
import '../models/quize_model.dart' as quiz;
import '../utils/endpoint_headers.dart';
import '../utils/s3_utils.dart';
import '../utils/api_error_handler.dart';
import 'hmac_auth_service.dart';

class DocumentsService {
  late final Dio _dioForQuiz;

  DocumentsService() {
    _dioForQuiz = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.quizModuleBaseUrl,
        connectTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5), // Fast send timeout
      ),
    );

    // Add HMAC authentication interceptor
    _dioForQuiz.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add HMAC auth headers to every request
          final authHeaders = HmacAuthService.buildAuthHeaders();
          options.headers.addAll(authHeaders);
          return handler.next(options);
        },
      ),
    );
  }

  Future<doc.DocumentsResponse> getFolderItems({required int folderId}) async {
    try {
      final response = await apiClient.dio.get(
        ApiEndpoints.folderItems,
        queryParameters: {'folder': folderId},
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return doc.DocumentsResponse.fromJson(response.data);
      } else {
        throw Exception(ApiErrorHandler.extractErrorMessage(response.data));
      }
    } on DioException catch (e) {
      throw ApiErrorHandler.createException(e);
    } catch (e) {
      throw ApiErrorHandler.createException(e);
    }
  }

  /// Save folder item after S3 upload
  Future<doc.Data> saveFolderItem({
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
        return doc.Data.fromJson(response.data);
      } else {
        throw Exception(ApiErrorHandler.extractErrorMessage(response.data));
      }
    } on DioException catch (e) {
      throw ApiErrorHandler.createException(e);
    } catch (e) {
      throw ApiErrorHandler.createException(e);
    }
  }

  /// Delete folder item
  Future<void> deleteFolderItem({required int itemId}) async {
    try {
      final response = await apiClient.dio.delete(
        '${ApiEndpoints.folderItems}$itemId/',
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(ApiErrorHandler.extractErrorMessage(response.data));
      }
    } on DioException catch (e) {
      throw ApiErrorHandler.createException(e);
    } catch (e) {
      throw ApiErrorHandler.createException(e);
    }
  }

  /// Generate quiz from selected documents
  Future<quiz.QuizModel> generateQuiz({
    required List<String> s3Filenames,
    int questionCount = 15,
  }) async {
    try {
      // Convert S3 filenames to full URLs
      final urls = s3Filenames
          .map((filename) => S3Utils.constructAssetUrl(filename))
          .join(',');

      print('🎯 [QUIZ] Generating quiz from URLs: $urls');

      // Make regular POST request
      final response = await _dioForQuiz.post(
        ApiEndpoints.generateQuiz,
        data: {'urls': urls},
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );
      print('🎯 [QUIZ] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        print('🎯 [QUIZ] Parsing response...');
        if (response.data is Map) {
          print('🎯 [QUIZ] Response is a Map with keys: ${response.data.keys}');
        }
        final quizModel = quiz.QuizModel.fromJson(response.data);
        print('✅ [QUIZ] Quiz parsed successfully');
        return quizModel;
      } else {
        throw Exception(ApiErrorHandler.extractErrorMessage(response.data));
      }
    } on DioException catch (e) {
      print('❌ [QUIZ] DioException: ${e.message}');
      throw ApiErrorHandler.createException(e);
    } catch (e, stackTrace) {
      print('❌ [QUIZ] Unexpected error: $e');
      throw ApiErrorHandler.createException(e);
    }
  }

  /// Save quiz attempt to backend
  Future<void> saveQuizAttempt({required quiz.QuizModel quizModel}) async {
    try {
      // Transform quiz items to match API format
      final items = quizModel.items?.map((item) {
        return {
          'id': item.id,
          'question': item.question,
          'options': {
            'A': item.options?.a,
            'B': item.options?.b,
            'C': item.options?.c,
            'D': item.options?.d,
          },
          'correct_label': item.correctLabel,
          'user_answer': item.selectedLabel,
        };
      }).toList();

      final requestBody = {'items': items};

      print('🎯 [QUIZ] Saving quiz attempt to backend');
      print('📝 [QUIZ] Items count: ${items?.length ?? 0}');

      final response = await apiClient.dio.post(
        ApiEndpoints.quizAttempts,
        data: requestBody,
        options: Options(
          headers: {
            WAInterceptorHeaders.requiresToken: true,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [QUIZ] Quiz attempt saved successfully');
      } else {
        throw Exception(ApiErrorHandler.extractErrorMessage(response.data));
      }
    } on DioException catch (e) {
      print('❌ [QUIZ] Failed to save quiz attempt: ${e.message}');
      throw ApiErrorHandler.createException(e);
    } catch (e) {
      print('❌ [QUIZ] Unexpected error while saving quiz attempt: $e');
      throw ApiErrorHandler.createException(e);
    }
  }

  /// Fetch quiz attempts list from backend
  Future<List<QuizAttempts>> getQuizAttemptsList({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      print('🎯 [QUIZ] Fetching quiz attempts list');
      print('📊 [QUIZ] Limit: $limit, Offset: $offset');

      final response = await apiClient.dio.get(
        ApiEndpoints.quizAttemptsList,
        queryParameters: {'limit': limit, 'offset': offset},
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200) {
        print('✅ [QUIZ] Quiz attempts fetched successfully');

        final quizHistoryResponse = QuizHistoryResponse.fromJson(response.data);

        final quizAttempts = quizHistoryResponse.data?.quizAttempts ?? [];

        if (quizAttempts.isEmpty) {
          print('📝 [QUIZ] No quiz attempts found');
          return [];
        }

        print('📝 [QUIZ] Found ${quizAttempts.length} quiz attempts');
        return quizAttempts;
      } else {
        throw Exception(ApiErrorHandler.extractErrorMessage(response.data));
      }
    } on DioException catch (e) {
      print('❌ [QUIZ] Failed to fetch quiz attempts: ${e.message}');
      throw ApiErrorHandler.createException(e);
    } catch (e) {
      print('❌ [QUIZ] Unexpected error while fetching quiz attempts: $e');
      throw ApiErrorHandler.createException(e);
    }
  }
}
