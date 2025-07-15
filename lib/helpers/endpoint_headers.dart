class WAInterceptorHeaders {
  static String requiresToken = 'requiresToken';
  static String authorization = 'Authorization';
  static String xRequestWith = 'X-Requested-With';
  static String contentType = 'Content-Type';
  static String accept = 'Accept';
}

class ApiEndpoints {
  //?BaseUrl
  static const String baseUrl =
      'https://wrasufsfxgtfqmpnhwkt.supabase.co/functions/v1/v0';
  static const String registerUser = '/register';
}
