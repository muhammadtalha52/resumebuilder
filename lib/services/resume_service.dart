import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../models/resume_parse_model.dart';

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
      throw UnsupportedFileException('Only PDF and DOCX files are supported');
    }
  }

  /// Check if a file is supported for resume parsing
  static bool isSupportedFile(String filePath) {
    final fileName = filePath.toLowerCase();
    return fileName.endsWith('.pdf') || fileName.endsWith('.docx');
  }

  /// Get human readable file size
  static String getFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    final i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
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
