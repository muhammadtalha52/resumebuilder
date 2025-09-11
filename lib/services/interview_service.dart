import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../models/interview_session_models.dart';

class InterviewService {
  late final Dio _dio;
  static const String baseUrl =
      'https://ia-dev.skillresy.com/api/'; // Interview API base URL

  InterviewService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        // Reduced for faster failure
        receiveTimeout: const Duration(seconds: 10),
        // 10 seconds max for help response
        sendTimeout: const Duration(seconds: 5), // Fast send timeout
      ),
    );

    // Configure SSL/TLS for development server
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      // For development server - bypass certificate verification
      client.badCertificateCallback = (cert, host, port) {
        // Only bypass for our specific development server
        return host.contains('ia-dev.skillresy.com') ||
            host.contains('skillresy.com');
      };
      return client;
    };

    // Note: Removed LogInterceptor to reduce console spam during streaming
  }

  /// Start a new interview session
  ///
  /// [request] - SessionStartRequest containing session parameters
  ///
  /// Returns a SessionStartResponse with status and session_id
  Future<SessionStartResponse> startSession(SessionStartRequest request) async {
    try {
      // Convert to form data format (application/x-www-form-urlencoded)
      final formData = <String, dynamic>{
        'session_type': request.sessionType,
        'role': request.role,
        'company_name': request.companyName,
        'job_description': request.jobDescription,
        'language': request.language,
        'resume_text': '',
      };

      // Debug log for resume_text
      final resumeLength = (request.resumeText?.length ?? 0);
      print(
        '[API] Sending session start request with resume_text: ${resumeLength > 0 ? '$resumeLength chars' : 'empty'}',
      );

      // Make API call with form data
      final response = await _dio.post(
        'session/start',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      );

      // Parse response
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          return SessionStartResponse.fromJson(response.data);
        } else {
          return SessionStartResponse.failure('Empty response from server');
        }
      } else {
        return SessionStartResponse.failure(
          'Failed to start session: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      // Handle Dio specific errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return SessionStartResponse.failure(
          'Request timeout. Please check your internet connection and try again.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        return SessionStartResponse.failure(
          'Unable to connect to server. Please check your internet connection.',
        );
      } else if (e.response?.statusCode == 400) {
        return SessionStartResponse.failure(
          'Invalid session parameters. Please check your inputs and try again.',
        );
      } else if (e.response?.statusCode == 401) {
        return SessionStartResponse.failure(
          'Authentication required. Please log in and try again.',
        );
      } else if (e.response?.statusCode == 422) {
        return SessionStartResponse.failure(
          'Unable to process your request. Please verify your data and try again.',
        );
      } else if (e.response?.statusCode == 500) {
        return SessionStartResponse.failure(
          'Server error occurred while starting session. Please try again later.',
        );
      } else {
        // Try to extract error message from response
        String errorMessage =
            'An error occurred while starting session. Please try again.';
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          } else if (data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          }
        }
        return SessionStartResponse.failure(errorMessage);
      }
    } catch (e) {
      return SessionStartResponse.failure(
        'Unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Get help during interview session
  ///
  /// [request] - SessionHelpRequest containing session_id and transcript
  ///
  /// Returns a SessionHelpResponse with AI assistance
  Future<SessionHelpResponse> getHelp(SessionHelpRequest request) async {
    try {
      // Convert to form data format (application/x-www-form-urlencoded)
      final formData = request.toFormData();

      // Make API call with form data
      final response = await _dio.post(
        'interview/help',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      );

      // Parse response
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          return SessionHelpResponse.fromJson(response.data);
        } else {
          return SessionHelpResponse.failure('Empty response from server');
        }
      } else {
        return SessionHelpResponse.failure(
          'Failed to get help: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      // Handle Dio specific errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return SessionHelpResponse.failure(
          'Request timeout. Please check your internet connection and try again.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        return SessionHelpResponse.failure(
          'Unable to connect to server. Please check your internet connection.',
        );
      } else if (e.response?.statusCode == 400) {
        return SessionHelpResponse.failure(
          'Invalid request. Please check your session or transcript.',
        );
      } else if (e.response?.statusCode == 401) {
        return SessionHelpResponse.failure(
          'Session not found or expired. Please start a new session.',
        );
      } else if (e.response?.statusCode == 422) {
        return SessionHelpResponse.failure(
          'Unable to process your request. Please try again.',
        );
      } else if (e.response?.statusCode == 500) {
        return SessionHelpResponse.failure(
          'Server error occurred while getting help. Please try again later.',
        );
      } else {
        // Try to extract error message from response
        String errorMessage =
            'An error occurred while getting help. Please try again.';
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          } else if (data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          }
        }
        return SessionHelpResponse.failure(errorMessage);
      }
    } catch (e) {
      return SessionHelpResponse.failure(
        'Unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Get streaming help during interview session
  ///
  /// [request] - SessionHelpRequest containing session_id and transcript
  ///
  /// Returns a Stream<String> that emits text chunks as they arrive
  Stream<String> getHelpStreaming(SessionHelpRequest request) async* {
    try {
      // Convert to form data format (application/x-www-form-urlencoded)
      final formData = request.toFormData();

      // Make streaming API call
      final response = await _dio.post(
        'interview/help',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
          responseType: ResponseType.stream,
        ),
      );

      print('InterviewService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final stream = response.data as ResponseBody;
        final streamController = StreamController<String>();

        // Process the stream data
        String buffer = '';

        stream.stream.listen(
          (List<int> data) {
            // Convert bytes to string
            final chunk = utf8.decode(data, allowMalformed: true);
            buffer += chunk;

            // Split by newlines and process complete lines
            final lines = buffer.split('\n');
            buffer = lines.removeLast(); // Keep incomplete line in buffer

            for (final line in lines) {
              // Parse Server-Sent Events format: "data: content"
              if (line.startsWith('data: ')) {
                final content = line.substring(6); // Remove "data: " prefix
                streamController.add(content);
              }
            }
          },
          onError: (error) {
            print('InterviewService: Stream error: $error');
            streamController.addError(error);
          },
          onDone: () {
            // Process any remaining buffer
            if (buffer.isNotEmpty && buffer.startsWith('data: ')) {
              final content = buffer.substring(6);
              print('InterviewService: Final content: "$content"');
              streamController.add(content);
            }
            print('InterviewService: Stream completed');
            streamController.close();
          },
        );

        yield* streamController.stream;
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: 'interview/help'),
          response: response,
          message: 'Failed to get streaming help: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      print('InterviewService: DioException: ${e.message}');

      // Handle specific error cases
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        yield 'Error: Request timeout. Please check your internet connection and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        yield 'Error: Unable to connect to server. Please check your internet connection.';
      } else if (e.response?.statusCode == 400) {
        yield 'Error: Invalid request. Please check your session or transcript.';
      } else if (e.response?.statusCode == 401) {
        yield 'Error: Session not found or expired. Please start a new session.';
      } else if (e.response?.statusCode == 422) {
        yield 'Error: Unable to process your request. Please try again.';
      } else if (e.response?.statusCode == 500) {
        yield 'Error: Server error occurred while getting help. Please try again later.';
      } else {
        yield 'Error: An error occurred while getting help. Please try again.';
      }
    } catch (e) {
      print('InterviewService: General exception: $e');
      yield 'Error: Unexpected error occurred: ${e.toString()}';
    }
  }

  /// Get streaming follow-up questions during interview session
  ///
  /// [request] - SessionFollowUpRequest containing session_id and transcript
  ///
  /// Returns a Stream<String> that emits text chunks as they arrive
  Stream<String> getFollowUpQuestionsStreaming(
    SessionFollowUpRequest request,
  ) async* {
    try {
      // Convert to form data format (application/x-www-form-urlencoded)
      final formData = request.toFormData();

      // Make streaming API call
      final response = await _dio.post(
        'interview/follow-up',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
          responseType: ResponseType.stream,
        ),
      );

      print(
        'InterviewService: Follow-up response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final stream = response.data as ResponseBody;
        final streamController = StreamController<String>();

        // Process the stream data
        String buffer = '';

        stream.stream.listen(
          (List<int> data) {
            // Convert bytes to string
            final chunk = utf8.decode(data, allowMalformed: true);
            buffer += chunk;

            // Split by newlines and process complete lines
            final lines = buffer.split('\n');
            buffer = lines.removeLast(); // Keep incomplete line in buffer

            for (final line in lines) {
              // Parse Server-Sent Events format: "data: content"
              if (line.startsWith('data: ')) {
                final content = line.substring(6); // Remove "data: " prefix
                streamController.add(content);
              }
            }
          },
          onError: (error) {
            print('InterviewService: Follow-up stream error: $error');
            streamController.addError(error);
          },
          onDone: () {
            // Process any remaining buffer
            if (buffer.isNotEmpty && buffer.startsWith('data: ')) {
              final content = buffer.substring(6);
              print('InterviewService: Final follow-up content: "$content"');
              streamController.add(content);
            }
            print('InterviewService: Follow-up stream completed');
            streamController.close();
          },
        );

        yield* streamController.stream;
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: 'interview/follow-up'),
          response: response,
          message:
              'Failed to get streaming follow-up: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      print('InterviewService: Follow-up DioException: ${e.message}');

      // Handle specific error cases
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        yield 'Error: Request timeout. Please check your internet connection and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        yield 'Error: Unable to connect to server. Please check your internet connection.';
      } else if (e.response?.statusCode == 400) {
        yield 'Error: Invalid request. Please check your session or transcript.';
      } else if (e.response?.statusCode == 401) {
        yield 'Error: Session not found or expired. Please start a new session.';
      } else if (e.response?.statusCode == 422) {
        yield 'Error: Unable to process your request. Please try again.';
      } else if (e.response?.statusCode == 500) {
        yield 'Error: Server error occurred while getting follow-up questions. Please try again later.';
      } else {
        yield 'Error: An error occurred while getting follow-up questions. Please try again.';
      }
    } catch (e) {
      print('InterviewService: Follow-up general exception: $e');
      yield 'Error: Unexpected error occurred: ${e.toString()}';
    }
  }
}

// Custom exceptions for interview service
abstract class InterviewServiceException implements Exception {
  final String message;

  InterviewServiceException(this.message);

  @override
  String toString() => message;
}

class SessionStartException extends InterviewServiceException {
  SessionStartException(super.message);
}
