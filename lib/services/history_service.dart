import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../utils/endpoint_headers.dart';

class HistoryService {
  final APIClient _apiClient = APIClient();

  Future<Map<String, dynamic>> getResumeHistory() async {
    try {
      final response = await _apiClient.dio.get(
        '/resume/resumes/',
        options: Options(headers: {WAInterceptorHeaders.requiresToken: 'true'}),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load resume history');
      }
    } catch (e) {
      throw Exception('Error fetching resume history: ${e.toString()}');
    }
  }

  Future<void> deleteResume(int id) async {
    try {
      final response = await _apiClient.dio.delete(
        '/resume/resumes/$id/',
        options: Options(headers: {WAInterceptorHeaders.requiresToken: 'true'}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete resume');
      }
    } catch (e) {
      throw Exception('Error deleting resume: ${e.toString()}');
    }
  }
}
