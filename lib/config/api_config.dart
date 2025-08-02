class ApiConfig {
  static const String baseUrl = 'https://api.skillresy.com';
  static const String apiVersion = '/v1';
  
  static String get apiUrl => '$baseUrl$apiVersion';
  
  static const Duration connectTimeout = Duration(seconds: 180);
  static const Duration receiveTimeout = Duration(seconds: 180);
  static const Duration sendTimeout = Duration(seconds: 300);
}