import 'package:dio/dio.dart';
import 'package:skillresy/main.dart';

import '../models/meeting_history_response.dart';
import '../utils/endpoint_headers.dart';

class MeetingHistoryService {
  Future<MeetingHistoryResponse> getMeetingHistory() async {
    try {
      final response = await apiClient.dio.get(
        '/interview/interviews/',
        options: Options(headers: {WAInterceptorHeaders.requiresToken: 'true'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MeetingHistoryResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to load meeting history');
      }
    } catch (e) {
      throw Exception('Error fetching meeting history: ${e.toString()}');
    }
  }

  Future<void> deleteMeeting(int id) async {
    try {
      final response = await apiClient.dio.delete(
        '/interview/interviews/$id/',
        options: Options(headers: {WAInterceptorHeaders.requiresToken: 'true'}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete meeting');
      }
    } catch (e) {
      throw Exception('Error deleting meeting: ${e.toString()}');
    }
  }
}
