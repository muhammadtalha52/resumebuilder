import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../main.dart';
import '../models/interview_session_models.dart';
import '../models/meeting_history_response.dart';
import '../utils/endpoint_headers.dart';
import 'hmac_auth_service.dart';

class InterviewService {
  late final Dio _dioForInterview;
  static const String baseUrl =
      'https://ia-dev.skillresy.com/api/'; // Interview API base URL

  InterviewService() {
    _dioForInterview = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5), // Fast send timeout
      ),
    );

    // Configure SSL/TLS for development server
    (_dioForInterview.httpClientAdapter as IOHttpClientAdapter)
        .createHttpClient = () {
      final client = HttpClient();
      // For development server - bypass certificate verification
      client.badCertificateCallback = (cert, host, port) {
        // Only bypass for our specific development server
        return host.contains('ia-dev.skillresy.com') ||
            host.contains('skillresy.com');
      };
      return client;
    };

    // Add HMAC authentication interceptor
    _dioForInterview.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add HMAC auth headers to every request
          final authHeaders = HmacAuthService.buildAuthHeaders();
          options.headers.addAll(authHeaders);
          return handler.next(options);
        },
      ),
    );

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
        'agenda': request.agenda,
        'language': request.language,
        'resume_text': request.resumeText,
      };

      // Debug log for resume_text
      final resumeLength = (request.resumeText?.length ?? 0);
      print(
        '[API] Sending session start request with resume_text: ${resumeLength > 0 ? '$resumeLength chars' : 'empty'}',
      );

      // Make API call with form data
      final response = await _dioForInterview.post(
        ApiEndpoints.sessionStart,
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
      final response = await _dioForInterview.post(
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

  /// Get next meeting assistance during meeting session
  ///
  /// [request] - SessionHelpRequest containing session_id and transcript
  ///
  /// Returns a Stream<String> that emits text chunks as they arrive for meeting assistance
  Stream<String> getNextMeetingHelp(SessionHelpRequest request) async* {
    try {
      // Convert to form data format (application/x-www-form-urlencoded)
      final formData = request.toFormData();

      // Make streaming API call to /next endpoint
      final response = await _dioForInterview.post(
        'meeting/next',
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

      print('InterviewService: Next response status: ${response.statusCode}');

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
            print('InterviewService: Next stream error: $error');
            streamController.addError(error);
          },
          onDone: () {
            // Process any remaining buffer
            if (buffer.isNotEmpty && buffer.startsWith('data: ')) {
              final content = buffer.substring(6);
              print('InterviewService: Final next content: "$content"');
              streamController.add(content);
            }
            print('InterviewService: Next stream completed');
            streamController.close();
          },
        );

        yield* streamController.stream;
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: 'interview/next'),
          response: response,
          message: 'Failed to get next meeting help: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      print('InterviewService: Next DioException: ${e.message}');

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
        yield 'Error: Server error occurred while getting meeting help. Please try again later.';
      } else {
        yield 'Error: An error occurred while getting meeting help. Please try again.';
      }
    } catch (e) {
      print('InterviewService: Next general exception: $e');
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
      final response = await _dioForInterview.post(
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

  /// End an interview session and get summary
  ///
  /// [sessionId] - The session ID to end
  ///
  /// Returns a Map containing status and summary
  Future<Map<String, dynamic>> endSession(String sessionId) async {
    try {
      final formData = {'session_id': sessionId};

      final response = await _dioForInterview.post(
        'session/end',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          return response.data as Map<String, dynamic>;
        } else {
          return {'status': 'error', 'summary': 'Empty response from server'};
        }
      } else {
        return {
          'status': 'error',
          'summary': 'Failed to end session: ${response.statusMessage}',
        };
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {
          'status': 'error',
          'summary': 'Request timeout. Please check your internet connection.',
        };
      } else if (e.type == DioExceptionType.connectionError) {
        return {'status': 'error', 'summary': 'Unable to connect to server.'};
      } else if (e.response?.statusCode == 400) {
        return {'status': 'error', 'summary': 'Invalid session ID.'};
      } else if (e.response?.statusCode == 401) {
        return {'status': 'error', 'summary': 'Session not found or expired.'};
      } else if (e.response?.statusCode == 500) {
        return {
          'status': 'error',
          'summary': 'Server error occurred while ending session.',
        };
      } else {
        String errorMessage = 'An error occurred while ending session.';
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          }
        }
        return {'status': 'error', 'summary': errorMessage};
      }
    } catch (e) {
      return {
        'status': 'error',
        'summary': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Save interview session to database using APIClient
  Future<Map<String, dynamic>> saveInterview(
    Map<String, dynamic> payloadData,
  ) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.saveInterviewData,
        data: payloadData,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'data': response.data,
          'message': 'Meeting saved successfully',
        };
      } else {
        return {
          'status': 'error',
          'message': 'Failed to save interview: ${response.statusMessage}',
        };
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {
          'status': 'error',
          'message': 'Request timeout. Please check your internet connection.',
        };
      } else if (e.type == DioExceptionType.connectionError) {
        return {'status': 'error', 'message': 'Unable to connect to server.'};
      } else if (e.response?.statusCode == 400) {
        return {'status': 'error', 'message': 'Invalid interview data.'};
      } else if (e.response?.statusCode == 401) {
        return {
          'status': 'error',
          'message': 'Authentication required. Please log in and try again.',
        };
      } else if (e.response?.statusCode == 403) {
        return {
          'status': 'error',
          'message': 'Permission denied. Unable to save interview.',
        };
      } else if (e.response?.statusCode == 500) {
        return {
          'status': 'error',
          'message': 'Server error occurred while saving interview.',
        };
      } else {
        String errorMessage = 'An error occurred while saving interview.';
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
        return {'status': 'error', 'message': errorMessage};
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Setup Scout chat session for meeting history
  ///
  /// [sessionId] - The meeting session ID
  /// [meeting] - MeetingHistoryItem containing meeting data
  ///
  /// Returns a Map containing status and setup response
  Future<Map<String, dynamic>> setupScoutChatSession(
    int sessionId,
    MeetingHistoryItem meeting,
  ) async {
    try {
      // Prepare transcription from meeting data
      String transcription = _buildTranscriptionFromMeeting(meeting);

      print('Scout: Setting up chat session for meeting ID: $sessionId');
      print('Scout: Transcription length: ${transcription.length} chars');

      final formData = {
        'session_id': sessionId,
        'transcription': transcription,
      };

      final response = await _dioForInterview.post(
        'chat/start',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          return {
            'status': 'success',
            'data': response.data,
            'message': 'Scout chat session setup successfully',
          };
        } else {
          return {
            'status': 'error',
            'message': 'Empty response from Scout chat setup',
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Failed to setup Scout chat: ${response.statusMessage}',
        };
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {
          'status': 'error',
          'message': 'Request timeout. Please check your internet connection.',
        };
      } else if (e.type == DioExceptionType.connectionError) {
        return {
          'status': 'error',
          'message': 'Unable to connect to Scout server.',
        };
      } else if (e.response?.statusCode == 400) {
        return {
          'status': 'error',
          'message': 'Invalid session data for Scout chat.',
        };
      } else if (e.response?.statusCode == 401) {
        return {
          'status': 'error',
          'message': 'Authentication required for Scout chat.',
        };
      } else if (e.response?.statusCode == 500) {
        return {
          'status': 'error',
          'message': 'Scout server error occurred. Please try again later.',
        };
      } else {
        String errorMessage = 'An error occurred while setting up Scout chat.';
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
        return {'status': 'error', 'message': errorMessage};
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Unexpected Scout chat error: ${e.toString()}',
      };
    }
  }

  /// Send message to Scout chat with streaming response
  ///
  /// [sessionId] - The session ID for the chat
  /// [message] - User's message to Scout
  ///
  /// Returns a Stream<String> that emits text chunks as they arrive
  Stream<String> sendScoutChatMessage(int sessionId, String message) async* {
    try {
      final formData = {
        'session_id': sessionId.toString(),
        'message': Uri.encodeComponent(message),
      };

      print('Scout: Sending message to session $sessionId');
      print('Scout: Message: $message');

      final response = await _dioForInterview.post(
        'chat/query',
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {
            'accept': 'application/json',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
          responseType: ResponseType.stream,
        ),
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
            print('Scout: Stream error: $error');
            streamController.addError(error);
          },
          onDone: () {
            // Process any remaining buffer
            if (buffer.isNotEmpty && buffer.startsWith('data: ')) {
              final content = buffer.substring(6);
              streamController.add(content);
            }
            print('Scout: Stream completed');
            streamController.close();
          },
        );

        yield* streamController.stream;
      } else {
        yield 'Error: Failed to get response from Scout (${response.statusCode})';
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        yield 'Request timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        yield 'Unable to connect to Scout server.';
      } else {
        String errorMessage = 'An error occurred while chatting with Scout.';
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          }
        }
        yield errorMessage;
      }
    } catch (e) {
      yield 'Unexpected error: ${e.toString()}';
    }
  }

  /// Build comprehensive transcription from meeting data
  String _buildTranscriptionFromMeeting(MeetingHistoryItem meeting) {
    List<String> transcriptionParts = [];

    // Add session type and basic info
    if (meeting.isInterview && meeting.companyName != null) {
      transcriptionParts.add(
        'This is an interview session for ${meeting.companyName}',
      );
      if (meeting.positionTitle != null) {
        transcriptionParts.add('for the position of ${meeting.positionTitle}');
      }
    } else if (meeting.isMeeting && meeting.roleIndustry != null) {
      transcriptionParts.add(
        'This is a meeting session in ${meeting.roleIndustry}',
      );
    }

    // Add key topics discussed
    if (meeting.keyTopics != null && meeting.keyTopics!.isNotEmpty) {
      transcriptionParts.add('Key topics discussed included:');
      transcriptionParts.addAll(meeting.keyTopics!);
    }

    // Add top moments
    if (meeting.topMomentsInInterview != null &&
        meeting.topMomentsInInterview!.isNotEmpty) {
      transcriptionParts.add('Important moments in the session:');
      transcriptionParts.addAll(meeting.topMomentsInInterview!);
    }

    // Add decisions made
    if (meeting.decisionsMade != null && meeting.decisionsMade!.isNotEmpty) {
      transcriptionParts.add('Decisions made during the session:');
      transcriptionParts.addAll(meeting.decisionsMade!);
    }

    // Add strengths highlighted
    if (meeting.strengthHighlight != null &&
        meeting.strengthHighlight!.isNotEmpty) {
      transcriptionParts.add('Strengths highlighted:');
      transcriptionParts.addAll(meeting.strengthHighlight!);
    }

    // Add areas for improvement
    if (meeting.weaknessHighlight != null &&
        meeting.weaknessHighlight!.isNotEmpty) {
      transcriptionParts.add('Areas for improvement mentioned:');
      transcriptionParts.addAll(meeting.weaknessHighlight!);
    }

    // Add action items
    if (meeting.actionItems != null && meeting.actionItems!.isNotEmpty) {
      transcriptionParts.add('Action items identified:');
      transcriptionParts.addAll(meeting.actionItems!);
    }

    // Add AI analytics if available
    if (meeting.aiDrivenInterviewAnalytics != null &&
        meeting.aiDrivenInterviewAnalytics!.isNotEmpty) {
      transcriptionParts.add('AI-driven insights:');
      transcriptionParts.addAll(meeting.aiDrivenInterviewAnalytics!);
    }

    // Join all parts with proper spacing
    String result = transcriptionParts.join('. ');

    // If no content, provide basic info
    if (result.isEmpty) {
      result = meeting.isInterview
          ? 'This was an interview session'
          : 'This was a meeting session';
    }

    return result;
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
