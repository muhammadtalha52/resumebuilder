import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_response.dart';
import '../services/api_client.dart';
import '../utils/endpoint_headers.dart';

final dashboardStatsProvider = FutureProvider.autoDispose
    .family<DashboardResponse, String?>((ref, filter) async {
      final apiClient = APIClient();

      final queryParams = filter != null ? '?filter=$filter' : '';
      final response = await apiClient.dio.get(
        '/auth/dashboard/stats/$queryParams',
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200) {
        return DashboardResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch dashboard stats');
      }
    });

final dashboardFilterProvider = StateProvider<String>((ref) => 'week');
