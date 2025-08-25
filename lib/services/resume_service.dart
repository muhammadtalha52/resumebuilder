import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../models/resume_parse_model.dart';
import '../models/generate_resume_response.dart';

class ResumeService {
  late final Dio _dio;
  static const String baseUrl =
      'https://skillresy-backend-dev-lb-2066517272.us-east-2.elb.amazonaws.com';

  ResumeService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5),
      ),
    );

    // Configure SSL/TLS for development server
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      // For development server - bypass certificate verification
      client.badCertificateCallback = (cert, host, port) {
        // Only bypass for our specific development server
        return host.contains('skillresy-backend-dev-lb') ||
            host.contains('us-east-2.elb.amazonaws.com');
      };
      return client;
    };

    // Add logging interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false, // Don't log file content
        responseBody: true,
        logPrint: (obj) => print('ResumeService: $obj'),
      ),
    );
  }

  /// Extract resume data from PDF/DOCX file
  ///
  /// Throws [ResumeParsingException] on parsing errors
  /// Throws [FileSizeException] if file is too large
  /// Throws [UnsupportedFileException] for invalid file types
  Future<ResumeParse> extractResumeData(File file) async {
    try {
      // Validate file before upload
      await validateFile(file);

      // Determine content type based on file extension
      final filename = file.path.split('/').last;
      final contentType = filename.toLowerCase().endsWith('.pdf')
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      // Prepare multipart form data - matching the curl format exactly
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: filename,
          contentType: DioMediaType.parse(contentType),
        ),
      });

      // Make API request - matching curl headers exactly
      final response = await _dio.post(
        '/extract-resume-data/',
        data: formData,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      // Check response status
      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle different response formats
        if (responseData is Map<String, dynamic>) {
          // Direct data response
          return ResumeParse.fromJson(responseData);
        } else if (responseData is Map && responseData.containsKey('data')) {
          // Wrapped response format
          return ResumeParse.fromJson(responseData['data']);
        } else {
          throw ResumeParsingException('Invalid response format from server');
        }
      } else {
        throw ResumeParsingException(
          'Failed to parse resume: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      // Handle Dio specific errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ResumeParsingException(
          'Request timeout. Please check your internet connection and try again.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        // Check if it's an SSL/Certificate error
        if (e.error is HandshakeException) {
          throw ResumeParsingException(
            'SSL certificate error. Please try again or contact support.',
          );
        }
        throw ResumeParsingException(
          'Unable to connect to server. Please check your internet connection.',
        );
      } else if (e.response?.statusCode == 400) {
        throw ResumeParsingException(
          'Invalid file format. Please upload a valid PDF or DOCX file.',
        );
      } else if (e.response?.statusCode == 413) {
        throw FileSizeException(
          'File size is too large. Please upload a file smaller than 5MB.',
        );
      } else if (e.response?.statusCode == 422) {
        throw ResumeParsingException(
          'Unable to extract data from this resume. Please try a different file or fill details manually.',
        );
      } else if (e.response?.statusCode == 500) {
        throw ResumeParsingException(
          'Server error occurred while parsing your resume. Please try again later.',
        );
      } else {
        // Try to extract error message from response
        String errorMessage =
            'An error occurred while parsing your resume. Please try again.';
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          }
        }
        throw ResumeParsingException(errorMessage);
      }
    } catch (e) {
      if (e is ResumeServiceException) {
        rethrow;
      }
      throw ResumeParsingException(
        'Unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Validate file before upload
  static Future<void> validateFile(File file) async {
    // Check if file exists
    if (!await file.exists()) {
      throw FileNotFoundException('Selected file no longer exists');
    }

    // Check file size
    final fileSizeInBytes = await file.length();
    const maxSizeInBytes = 5 * 1024 * 1024; // 5MB

    if (fileSizeInBytes > maxSizeInBytes) {
      throw FileSizeException(
        'File size (${getFileSize(fileSizeInBytes)}) exceeds 5MB limit',
      );
    }

    // Check file extension
    if (!isSupportedFile(file.path)) {
      throw UnsupportedFileException(
        'Only PDF, DOCX, and JSON files are supported',
      );
    }
  }

  /// Check if a file is supported for resume parsing
  static bool isSupportedFile(String filePath) {
    final fileName = filePath.toLowerCase();
    return fileName.endsWith('.pdf') ||
        fileName.endsWith('.docx') ||
        fileName.endsWith('.json');
  }

  /// Get human readable file size
  static String getFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    final i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Generate a tailored resume based on user data and job requirements
  ///
  /// [file] - Resume file (PDF, JSON, or DOCX)
  /// [jobUrl] - URL of the job posting (optional if jobDescription provided)
  /// [jobDescription] - Text description of the job (optional if jobUrl provided)
  /// [template] - Template to use ("resume" for standard, "ats" for ATS-friendly, "modern" for modern)
  ///
  /// Returns a GenerateResumeResponse containing resume data and base64 encoded PDF
  Future<GenerateResumeResponse> generateResume({
    required File file,
    String? jobUrl,
    String? jobDescription,
    required String template,
  }) async {
    try {
      // Validate that either jobUrl or jobDescription is provided
      if ((jobUrl == null || jobUrl.isEmpty) &&
          (jobDescription == null || jobDescription.isEmpty)) {
        throw GenerateResumeException(
          'Either job URL or job description must be provided',
        );
      }

      // Validate file before upload
      await validateFile(file);

      // Determine content type based on file extension
      final filename = file.path.split('/').last;
      final contentType = filename.toLowerCase().endsWith('.pdf')
          ? 'application/pdf'
          : filename.toLowerCase().endsWith('.json')
          ? 'application/json'
          : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      // Prepare multipart form data
      final formData = FormData();

      // Add file
      formData.files.add(
        MapEntry(
          'file',
          await MultipartFile.fromFile(
            file.path,
            filename: filename,
            contentType: DioMediaType.parse(contentType),
          ),
        ),
      );

      // Add optional parameters if provided
      if (jobUrl != null && jobUrl.isNotEmpty) {
        formData.fields.add(MapEntry('job_url', jobUrl));
      }

      if (jobDescription != null && jobDescription.isNotEmpty) {
        formData.fields.add(MapEntry('job_description', jobDescription));
      }

      // Add template parameter
      formData.fields.add(MapEntry('template', template));

      // Make API request
      final response = await _dio.post(
        '/generate-resume/',
        data: formData,
        options: Options(
          headers: {
            'accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      // Check response status
      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle different response formats and parse using GenerateResumeResponse model
        if (responseData is Map<String, dynamic>) {
          return GenerateResumeResponse.fromJson(responseData);
        } else if (responseData is Map && responseData.containsKey('data')) {
          return GenerateResumeResponse.fromJson(responseData['data']);
        } else {
          throw GenerateResumeException('Invalid response format from server');
        }
      } else {
        throw GenerateResumeException(
          'Failed to generate resume: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      // Handle Dio specific errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw GenerateResumeException(
          'Request timeout. Please check your internet connection and try again.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw GenerateResumeException(
          'Unable to connect to server. Please check your internet connection.',
        );
      } else if (e.response?.statusCode == 400) {
        throw GenerateResumeException(
          'Invalid request. Please check your inputs and try again.',
        );
      } else if (e.response?.statusCode == 422) {
        throw GenerateResumeException(
          'Unable to process your request. Please verify your data and try again.',
        );
      } else if (e.response?.statusCode == 500) {
        throw GenerateResumeException(
          'Server error occurred while generating your resume. Please try again later.',
        );
      } else {
        // Try to extract error message from response
        String errorMessage =
            'An error occurred while generating your resume. Please try again.';
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          }
        }
        throw GenerateResumeException(errorMessage);
      }
    } catch (e) {
      if (e is ResumeServiceException) {
        rethrow;
      }
      throw GenerateResumeException(
        'Unexpected error occurred: ${e.toString()}',
      );
    }
  }
}

// Custom exceptions for better error handling
abstract class ResumeServiceException implements Exception {
  final String message;

  ResumeServiceException(this.message);

  @override
  String toString() => message;
}

class ResumeParsingException extends ResumeServiceException {
  ResumeParsingException(super.message);
}

class FileSizeException extends ResumeServiceException {
  FileSizeException(super.message);
}

class UnsupportedFileException extends ResumeServiceException {
  UnsupportedFileException(super.message);
}

class FileNotFoundException extends ResumeServiceException {
  FileNotFoundException(super.message);
}

class GenerateResumeException extends ResumeServiceException {
  GenerateResumeException(super.message);
}
