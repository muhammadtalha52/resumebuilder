import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_dashboard_response.dart';
import '../services/api_client.dart';
import '../utils/endpoint_headers.dart';

final studentDashboardStatsProvider =
    FutureProvider.autoDispose<StudentDashboardResponse>((ref) async {
      final apiClient = APIClient();

      final response = await apiClient.dio.get(
        '/auth/student-dashboard/',
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200) {
        return StudentDashboardResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch student dashboard stats');
      }
    });
