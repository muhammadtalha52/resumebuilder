import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:skillresy/models/save_doc_response.dart';
import '../models/resume_parse_model.dart';
import '../models/generate_resume_response.dart';
import '../utils/endpoint_headers.dart';
import '../main.dart';
import 'hmac_auth_service.dart';

class ResumeService {
  late final Dio _dioForResumes;

  ResumeService() {
    _dioForResumes = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.resumeModuleBaseUrl,
        connectTimeout: const Duration(minutes: 10),
        receiveTimeout: const Duration(minutes: 10),
        sendTimeout: const Duration(minutes: 10),
      ),
    );

    // Configure SSL/TLS for development server
    (_dioForResumes.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
        () {
          final client = HttpClient();
          // For development server - bypass certificate verification
          client.badCertificateCallback = (cert, host, port) {
            // Only bypass for our specific development server
            return host.contains('skillresy-backend-dev-lb') ||
                host.contains('us-east-2.elb.amazonaws.com');
          };
          return client;
        };

    // Add HMAC authentication interceptor
    _dioForResumes.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add HMAC auth headers to every request
          final authHeaders = HmacAuthService.buildAuthHeaders();
          options.headers.addAll(authHeaders);
          return handler.next(options);
        },
      ),
    );

    // Add logging interceptor for debugging
    _dioForResumes.interceptors.add(
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
      final response = await _dioForResumes.post(
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

  /// Regenerate specific sections of a resume
  ///
  /// [resumeData] - JSON string containing existing resume data
  /// [sectionsToRegenerate] - Comma-separated list of sections to regenerate
  /// [jobUrl] - URL of the job posting (optional if jobDescription provided)
  /// [jobDescription] - Text description of the job (optional if jobUrl provided)
  /// [template] - Template to use ("resume" for standard, "ats" for ATS-friendly, "modern" for modern)
  ///
  /// Returns a GenerateResumeResponse containing updated resume data and base64 encoded PDF
  Future<GenerateResumeResponse> regenerateSections({
    required String resumeData,
    required String sectionsToRegenerate,
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

      // Prepare form data
      final formData = FormData();

      // Add resume data as JSON string
      formData.fields.add(MapEntry('resume_data', resumeData));

      // Add sections to regenerate
      formData.fields.add(
        MapEntry('sections_to_regenerate', sectionsToRegenerate),
      );

      // Add optional parameters if provided
      // Prioritize job_description if both are provided (API accepts only one)
      if (jobDescription != null && jobDescription.isNotEmpty) {
        formData.fields.add(MapEntry('job_description', jobDescription));
      } else if (jobUrl != null && jobUrl.isNotEmpty) {
        formData.fields.add(MapEntry('job_url', jobUrl));
      }

      // Add template
      formData.fields.add(MapEntry('template', template));

      // Make API call to regenerate sections endpoint
      final response = await _dioForResumes.post(
        '/regenerate-sections/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      // Parse response
      if (response.data != null) {
        return GenerateResumeResponse.fromJson(response.data);
      } else {
        throw GenerateResumeException('Empty response from server');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response!.data is Map
            ? e.response!.data['detail'] ?? 'Failed to regenerate sections'
            : 'Failed to regenerate sections';
        throw GenerateResumeException(message);
      } else {
        throw GenerateResumeException(
          'Network error: ${e.message ?? 'Failed to regenerate sections'}',
        );
      }
    } catch (e) {
      throw GenerateResumeException('Unexpected error: ${e.toString()}');
    }
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
      // Prioritize job_description if both are provided (API accepts only one)
      if (jobDescription != null && jobDescription.isNotEmpty) {
        formData.fields.add(MapEntry('job_description', jobDescription));
      } else if (jobUrl != null && jobUrl.isNotEmpty) {
        formData.fields.add(MapEntry('job_url', jobUrl));
      }

      // Add template parameter
      formData.fields.add(MapEntry('template', template));

      // Make API request
      final response = await _dioForResumes.post(
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

  /// Convert existing resume JSON data to PDF using specified template
  ///
  /// [resumeData] - JSON string containing complete resume data
  /// [template] - Template to use ("resume" for standard, "ats" for ATS-friendly, "modern" for modern)
  ///
  /// Returns the base64 encoded PDF string
  Future<String> convertResumeToPdf({
    required String resumeData,
    required String template,
  }) async {
    try {
      // Make API call to convert-resume-to-pdf endpoint
      final response = await _dioForResumes.post(
        '/convert-resume-to-pdf/',
        data: {'resume_data': resumeData, 'template': template},
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {'accept': 'application/json'},
        ),
      );

      // Parse response and extract PDF base64 string
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          // Check for pdf_base64 key or other PDF-related keys
          if (responseData.containsKey('pdf_base64')) {
            final pdfData = responseData['pdf_base64'] as String;
            return pdfData;
          } else {
            // Look for other possible PDF keys
            for (String key in responseData.keys) {
              if (key.toLowerCase().contains('pdf')) {
                final pdfData = responseData[key] as String;
                return pdfData;
              }
            }
            throw ConvertToPdfException(
              'PDF data not found in server response. Available keys: ${responseData.keys.join(", ")}',
            );
          }
        } else if (responseData is Map && responseData.containsKey('data')) {
          final data = responseData['data'] as Map<String, dynamic>;
          if (data.containsKey('pdf_base64')) {
            final pdfData = data['pdf_base64'] as String;

            return pdfData;
          } else {
            throw ConvertToPdfException(
              'PDF data not found in server response data. Available keys: ${data.keys.join(", ")}',
            );
          }
        } else {
          throw ConvertToPdfException('Invalid response format from server');
        }
      } else {
        throw ConvertToPdfException(
          'Failed to convert resume to PDF: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      // Handle Dio specific errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ConvertToPdfException(
          'Request timeout. Please check your internet connection and try again.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw ConvertToPdfException(
          'Unable to connect to server. Please check your internet connection.',
        );
      } else if (e.response?.statusCode == 400) {
        throw ConvertToPdfException('Invalid resume data. Please try again.');
      } else if (e.response?.statusCode == 422) {
        throw ConvertToPdfException(
          'Unable to process resume data. Please verify your information and try again.',
        );
      } else if (e.response?.statusCode == 500) {
        throw ConvertToPdfException(
          'Server error occurred while generating PDF. Please try again later.',
        );
      } else {
        // Try to extract error message from response
        String errorMessage =
            'An error occurred while converting resume to PDF. Please try again.';
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          }
        }
        throw ConvertToPdfException(errorMessage);
      }
    } catch (e) {
      if (e is ResumeServiceException) {
        rethrow;
      }
      throw ConvertToPdfException('Unexpected error occurred: ${e.toString()}');
    }
  }

  /// Upload PDF file to S3 storage
  ///
  /// [pdfFile] - PDF file to upload
  ///
  /// Returns the S3 file name/URL from the API response
  Future<SaveDocResponse> uploadDocsToS3(File pdfFile) async {
    try {
      // Validate file before upload
      if (!await pdfFile.exists()) {
        throw SaveResumeException('File no longer exists');
      }

      // Check file size (must match client-side validation)
      final fileSizeInBytes = await pdfFile.length();
      const maxSizeInBytes = 5 * 1024 * 1024; // 5MB limit

      if (fileSizeInBytes > maxSizeInBytes) {
        throw SaveResumeException(
          'File size (${getFileSize(fileSizeInBytes)}) exceeds 5MB limit',
        );
      }

      // Prepare multipart form data
      final filename = pdfFile.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          pdfFile.path,
          filename: filename,
          contentType: DioMediaType.parse('application/pdf'),
        ),
      });

      // Use singleton APIClient for authenticated requests
      final response = await apiClient.dio.post(
        '/auth/upload-docs-to-s3/',
        data: formData,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      // Parse response
      if (response.statusCode == 200 || response.statusCode == 201) {
        SaveDocResponse saveDocResponse = SaveDocResponse.fromJson(
          jsonDecode(response.toString()),
        );
        if (saveDocResponse.s3FileName == null ||
            saveDocResponse.s3FileName != '') {
          return saveDocResponse;
        } else {
          throw SaveResumeException(
            'Invalid response format from S3 upload API',
          );
        }
      } else {
        throw SaveResumeException(
          'Failed to upload PDF to S3: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      // Handle Dio specific errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw SaveResumeException(
          'Upload timeout. Please check your internet connection and try again.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw SaveResumeException(
          'Unable to connect to server. Please check your internet connection.',
        );
      } else if (e.response?.statusCode == 413) {
        throw SaveResumeException(
          'PDF file is too large. Please try again with a smaller file.',
        );
      } else if (e.response?.statusCode == 400) {
        throw SaveResumeException('Invalid PDF file. Please try again.');
      } else if (e.response?.statusCode == 500) {
        throw SaveResumeException(
          'Server error occurred while uploading PDF. Please try again later.',
        );
      } else {
        // Try to extract error message from response
        String errorMessage = 'Failed to upload PDF to S3. Please try again.';
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error')) {
            errorMessage = data['error'].toString();
          }
        }
        throw SaveResumeException(errorMessage);
      }
    } catch (e) {
      if (e is ResumeServiceException) {
        rethrow;
      }
      throw SaveResumeException(
        'Unexpected error during PDF upload: ${e.toString()}',
      );
    }
  }

  /// Save generated resume to backend
  ///
  /// [title] - Title of the resume (e.g., "John Doe - Senior Engineer Resume")
  /// [template] - Template used ("resume", "ats", or "modern")
  /// [companyName] - Company name from job targeting
  /// [jobTitle] - Job title from job targeting
  /// [linkedinJobUrl] - LinkedIn job URL (optional)
  /// [jobDescription] - Job description text (optional)
  /// [resumeData] - Complete resume data JSON object
  /// [resumeUrl] - S3 URL of the uploaded PDF file (optional)
  ///
  /// Returns the saved resume ID from the backend
  Future<Map<String, dynamic>> saveResume({
    required String title,
    String? companyName,
    String? jobTitle,
    String? linkedinJobUrl,
    String? jobDescription,
    required Map<String, dynamic> resumeData,
    String? resumeUrl,
  }) async {
    try {
      // Prepare request body
      final requestBody = {
        'title': title,
        'template': "classic",
        'resume_type': 'self',
        'is_active': true,
        'is_public': false,
        'company_name': companyName ?? '',
        'job_title': jobTitle ?? '',
        'linkedin_job_url': linkedinJobUrl ?? '',
        'job_description': jobDescription ?? '',
        'resume_url': resumeUrl ?? '',
        //'content': resumeData.toString(),
      };

      print('💾 Saving resume with data: ${requestBody.keys.toList()}');

      // Make API call to save resume using authenticated APIClient
      final response = await apiClient.dio.post(
        '/resume/resumes/',
        data: requestBody,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      // Parse response
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          return response.data as Map<String, dynamic>;
        } else {
          throw SaveResumeException('Empty response from server');
        }
      } else {
        throw SaveResumeException(
          'Failed to save resume: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw SaveResumeException('Unexpected error occurred: ${e.toString()}');
    } catch (e) {
      if (e is ResumeServiceException) {
        rethrow;
      }
      throw SaveResumeException('Unexpected error occurred: ${e.toString()}');
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

class ConvertToPdfException extends ResumeServiceException {
  ConvertToPdfException(super.message);
}

class SaveResumeException extends ResumeServiceException {
  SaveResumeException(super.message);
}
