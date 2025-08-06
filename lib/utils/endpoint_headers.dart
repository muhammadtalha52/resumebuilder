class WAInterceptorHeaders {
  static String requiresToken = 'requiresToken';
  static String authorization = 'Authorization';
  static String xRequestWith = 'X-Requested-With';
  static String contentType = 'Content-Type';
  static String accept = 'Accept';
}

class ApiEndpoints {
  static const String baseUrl = 'https://api-dev.skillresy.com/api';
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String educationData =
      '/resume/degree-types-subject-institutes/';
}
