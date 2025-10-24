import 'package:dio/dio.dart';

/// Utility class for handling API errors consistently across the app
class ApiErrorHandler {
  /// Extracts error message from server response data
  /// Checks for common error fields: 'error', 'message', 'detail'
  static String extractErrorMessage(dynamic responseData, {String? fallback}) {
    if (responseData == null) {
      return fallback ?? 'An error occurred';
    }

    // If response is a Map, check for common error fields
    if (responseData is Map) {
      final errorMessage =
          responseData['error']?.toString() ??
          responseData['message']?.toString() ??
          responseData['detail']?.toString();

      if (errorMessage != null && errorMessage.isNotEmpty) {
        return errorMessage;
      }
    }

    // If response is a String, return it directly
    if (responseData is String && responseData.isNotEmpty) {
      return responseData;
    }

    return fallback ?? 'An error occurred';
  }

  /// Handles DioException and returns user-friendly error message
  static String handleDioException(DioException e) {
    if (e.response != null) {
      return extractErrorMessage(e.response!.data, fallback: e.message);
    }
    return e.message ?? 'Network error occurred';
  }

  /// Generic exception handler that wraps error in Exception with clean message
  static Exception createException(dynamic error, {String? fallback}) {
    if (error is DioException) {
      return Exception(handleDioException(error));
    }

    if (error is Exception) {
      // Extract message from Exception
      final errorStr = error.toString();
      if (errorStr.startsWith('Exception: ')) {
        return Exception(errorStr.substring('Exception: '.length));
      }
      return error;
    }

    return Exception(fallback ?? error.toString());
  }
}
