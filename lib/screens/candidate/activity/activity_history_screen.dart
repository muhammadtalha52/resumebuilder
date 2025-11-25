import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../models/dashboard_response.dart';
import '../../../services/api_client.dart';
import '../../../utils/date_helpers.dart';
import '../../../utils/endpoint_headers.dart';
import '../../../widgets/common/custom_app_bar.dart';

// Activity history provider - calls dashboard stats API with limit parameter
final activityHistoryProvider = FutureProvider.autoDispose<DashboardResponse>((
  ref,
) async {
  final apiClient = APIClient();

  // Call same endpoint as dashboard but with limit parameter for activity history
  final response = await apiClient.dio.get(
    '/auth/dashboard/stats/?limit=100',
    options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
  );

  if (response.statusCode == 200) {
    return DashboardResponse.fromJson(response.data);
  } else {
    throw Exception('Failed to fetch activity history');
  }
});

class ActivityHistoryScreen extends ConsumerStatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  ConsumerState<ActivityHistoryScreen> createState() =>
      _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends ConsumerState<ActivityHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(activityHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CustomAppBar(
        title: AppBarWidgets.foxWithTitle(title: "Activity History"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/icons/background.png',
              fit: BoxFit.cover,
            ),
          ),
          historyAsync.when(
            data: (dashboardResponse) {
              final activities = dashboardResponse.data?.items ?? [];
              if (activities.isEmpty) {
                return _buildEmptyState();
              }
              return _buildActivityList(activities, context);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load activities',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No activities yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your activity history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List<Items> activities, BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: false,
        itemCount: activities.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.withValues(alpha: 0.2),
        ),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityCard(activity, context);
        },
      ),
    );
  }

  String _formatActivityDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateHelpers.formatToDisplayDate(date);
    } catch (e) {
      return '';
    }
  }

  Widget _buildActivityCard(Items activity, BuildContext context) {
    final activityType = activity.type?.toLowerCase() ?? '';
    final iconPath = activityType == 'resume'
        ? 'assets/icons/resume.png'
        : 'assets/icons/session.png';

    return InkWell(
      onTap: () {
        // Navigate based on activity type
        if (activityType == 'resume') {
          context.push('/resume/history');
        } else if (activityType == 'interview' || activityType == 'meeting') {
          context.push('/meeting/history');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.activityTypeDisplay ?? activity.subTitle ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatActivityDate(
                      activity.timestamp ?? activity.createdAt ?? '',
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Image.asset(
              iconPath,
              width: 22,
              height: 22,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
