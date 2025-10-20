import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:skillresy/main.dart';
import '../models/documents_response.dart' as doc;
import '../models/quiz_history_response.dart';
import '../models/quize_model.dart' as quiz;
import '../utils/endpoint_headers.dart';
import '../utils/s3_utils.dart';

class DocumentsService {
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

  /// Delete folder item
  Future<void> deleteFolderItem({required int itemId}) async {
    try {
      final response = await apiClient.dio.delete(
        '${ApiEndpoints.folderItems}$itemId/',
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete document');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to delete document';

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
      throw Exception('Failed to delete document: $e');
    }
  }

  /// Generate quiz from selected documents with SSE real-time progress tracking
  Future<quiz.QuizModel> generateQuiz({
    required List<String> s3Filenames,
    int questionCount = 15,
    void Function(double progress, String message)? onProgress,
  }) async {
    try {
      // Convert S3 filenames to full URLs
      final urls = s3Filenames
          .map((filename) => S3Utils.constructAssetUrl(filename))
          .join(',');

      // Report initial progress
      onProgress?.call(0.0, 'Connecting to server...');

      // Create separate Dio instance for quiz service
      final quizDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.quizBaseUrl,
          connectTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      // Use ResponseType.stream to receive SSE events
      final response = await quizDio.post(
        ApiEndpoints.generateQuiz,
        data: {'urls': urls},
        options: Options(
          headers: {
            'Accept': 'text/event-stream',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          responseType: ResponseType.stream,
        ),
      );

      // Buffer to accumulate incomplete SSE messages
      String buffer = '';
      quiz.QuizModel? finalQuiz;

      // Listen to SSE stream
      await for (final chunk in response.data.stream) {
        final text = String.fromCharCodes(chunk);
        buffer += text;

        // Process complete SSE messages (split by double newline)
        final messages = buffer.split('\n\n');
        buffer = messages.removeLast(); // Keep incomplete message in buffer

        for (final message in messages) {
          if (message.trim().isEmpty) continue;

          // Parse SSE data line
          final lines = message.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6); // Remove 'data: ' prefix

              try {
                final data = jsonDecode(jsonStr) as Map<String, dynamic>;
                final type = data['type'] as String?;

                if (type == 'progress') {
                  final percent = data['percent'] as int;
                  final msg = data['message'] as String;
                  final progressValue = percent / 100.0;

                  onProgress?.call(progressValue, msg);
                } else if (type == 'result') {
                  final result = data['result'] as Map<String, dynamic>;
                  finalQuiz = quiz.QuizModel.fromJson(result);
                  onProgress?.call(1.0, 'Quiz generated successfully!');
                }
              } catch (e) {
                print('⚠️  [QUIZ] Parse error: $e');
              }
            }
          }
        }
      }

      if (finalQuiz == null) {
        throw Exception('Quiz generation completed but no result received');
      }

      return finalQuiz;
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to generate quiz';

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
      print('❌ [QUIZ] Unexpected error: $e');

      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to generate quiz: $e');
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
        throw Exception('Failed to save quiz attempt');
      }
    } on DioException catch (e) {
      print('❌ [QUIZ] Failed to save quiz attempt: ${e.message}');

      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to save quiz attempt';

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
      print('❌ [QUIZ] Unexpected error while saving quiz attempt: $e');

      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to save quiz attempt: $e');
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
        throw Exception('Failed to fetch quiz attempts');
      }
    } on DioException catch (e) {
      print('❌ [QUIZ] Failed to fetch quiz attempts: ${e.message}');

      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = 'Failed to fetch quiz attempts';

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
      print('❌ [QUIZ] Unexpected error while fetching quiz attempts: $e');

      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to fetch quiz attempts: $e');
    }
  }
}
