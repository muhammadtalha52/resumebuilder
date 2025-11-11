import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/usage_allocation_model.dart';
import '../services/api_client.dart';
import '../utils/endpoint_headers.dart';

// Usage State
class UsageState extends Equatable {
  const UsageState({this.isLoading = false, this.usageAllocation, this.error});

  final bool isLoading;
  final UsageAllocation? usageAllocation;
  final String? error;

  UsageState copyWith({
    bool? isLoading,
    UsageAllocation? usageAllocation,
    String? error,
  }) {
    return UsageState(
      isLoading: isLoading ?? this.isLoading,
      usageAllocation: usageAllocation ?? this.usageAllocation,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, usageAllocation, error];
}

// Usage State Notifier
class UsageNotifier extends StateNotifier<UsageState> {
  UsageNotifier() : super(const UsageState());

  final _apiClient = APIClient();

  Future<void> fetchUsageAllocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.planAllocation,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: 'true'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success' && data['data'] != null) {
          final usageAllocation = UsageAllocation.fromJson(data['data']);
          state = state.copyWith(
            isLoading: false,
            usageAllocation: usageAllocation,
          );
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch usage data');
        }
      } else {
        throw Exception('Failed to fetch usage data');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const UsageState();
  }
}

// Provider
final usageProvider = StateNotifierProvider<UsageNotifier, UsageState>((ref) {
  return UsageNotifier();
});
