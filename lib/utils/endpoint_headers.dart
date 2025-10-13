class WAInterceptorHeaders {
  static String requiresToken = 'requiresToken';
  static String authorization = 'Authorization';
  static String xRequestWith = 'X-Requested-With';
  static String contentType = 'Content-Type';
  static String accept = 'Accept';
}

class ApiEndpoints {
  static const String baseUrl = 'https://api-dev.skillresy.com/api';
  //static const String baseUrl = 'http://192.168.12.16:8000/api';
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String profileUpdate = '/auth/profile/';
  static const String uploadProfilePhoto = '/auth/upload-profile-image/';
  static const String educationData =
      '/resume/degree-types-subject-institutes/';
  static const String sessionStart = '/session/start';
  static const String saveInterviewData = '/interview/interviews/';
  static const String folders = '/auth/folders/';
  static const String folderItems = '/auth/folder-items/';
}
