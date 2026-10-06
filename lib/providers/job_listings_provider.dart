import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../models/job_listing_model.dart';
import '../utils/endpoint_headers.dart';
import '../services/analytics_service.dart';

class JobListingsNotifier extends StateNotifier<JobListingsState> {
  JobListingsNotifier() : super(JobListingsState());

  Future<void> fetchJobs(String jobTitle, {String? location}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = <String, dynamic>{'q': jobTitle};
      if (location != null && location.trim().isNotEmpty) {
        queryParams['location'] = location.trim();
      }

      final response = await apiClient.dio.get(
        ApiEndpoints.matchingJobs,
        queryParameters: queryParams,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      debugPrint('[JobListings] Raw API response: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['results'] as List?) ??
                  (response.data['data'] as List?) ??
                  [];
        final jobs = data
            .map((json) => JobListing.fromJson(json as Map<String, dynamic>))
            .toList();
        final alreadyApplied = jobs
            .where((job) => job.hasApplied)
            .map((job) => job.id)
            .toSet();
        state = state.copyWith(
          jobs: jobs,
          isLoading: false,
          appliedJobIds: {...state.appliedJobIds, ...alreadyApplied},
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load jobs. Please try again.',
        );
      }
    } on DioException catch (e) {
      debugPrint('Job fetch error: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error:
            e.response?.data?['message']?.toString() ??
            'Failed to load jobs. Please try again.',
      );
    } catch (e) {
      debugPrint('Job fetch error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> applyToJob(int jobId, String pdfBase64) async {
    state = state.copyWith(applyingJobIds: {...state.applyingJobIds, jobId});

    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.applyToJob,
        data: {'job_id': jobId, 'resume_pdf_base64': pdfBase64},
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      final applying = Set<int>.from(state.applyingJobIds)..remove(jobId);

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(
          appliedJobIds: {...state.appliedJobIds, jobId},
          applyingJobIds: applying,
        );
        
        // Find the job to log its properties
        try {
          final job = state.jobs.firstWhere((j) => j.id == jobId);
          AnalyticsService.logBackendEvent('seeker_job_applied', properties: {
            'job_title': job.jobTitle,
            'company': job.companyName,
          });
        } catch (e) {
          AnalyticsService.logBackendEvent('seeker_job_applied');
        }
      } else {
        state = state.copyWith(
          applyingJobIds: applying,
          error: 'Failed to apply. Please try again.',
        );
      }
    } on DioException catch (e) {
      final applying = Set<int>.from(state.applyingJobIds)..remove(jobId);
      state = state.copyWith(
        applyingJobIds: applying,
        error:
            e.response?.data?['message']?.toString() ??
            'Failed to apply. Please try again.',
      );
    } catch (e) {
      final applying = Set<int>.from(state.applyingJobIds)..remove(jobId);
      state = state.copyWith(
        applyingJobIds: applying,
        error: 'Failed to apply: ${e.toString()}',
      );
    }
  }
}

final jobListingsProvider =
    StateNotifierProvider<JobListingsNotifier, JobListingsState>(
      (ref) => JobListingsNotifier(),
    );
