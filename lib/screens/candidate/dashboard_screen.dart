import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/date_helpers.dart';
import '../common/main_screen.dart';

final selectedTabProvider = StateProvider<int>((ref) => 1);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // Listen to tab changes and refresh dashboard when user switches to dashboard tab
    ref.listen<int>(navigationIndexProvider, (previous, current) {
      // Only refresh when switching TO dashboard tab (index 0) from another tab
      if (current == 0 && previous != null && previous != 0) {
        print(
          '[CandidateDashboard] Tab switched to dashboard - refreshing data',
        );
        ref.invalidate(dashboardStatsProvider);
      }
    });
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CustomAppBar(
        title: AppBarWidgets.foxLogo(),
        actions: [AppBarWidgets.premiumBadge()],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/icons/background.png',
              fit: BoxFit.cover,
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              // Invalidate dashboard provider to trigger refresh
              ref.invalidate(dashboardStatsProvider);
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildWelcomeSection(ref),
                  const SizedBox(height: 10),
                  _buildProgressAndMetricsSection(ref),
                  const SizedBox(height: 24),
                  _buildRecentActivitySection(ref),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(WidgetRef ref) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
    final authState = ref.watch(authProvider);

    // Get user's first name or fallback
    String firstName = 'User';
    if (authState.user?.firstName != null &&
        authState.user!.firstName!.isNotEmpty) {
      firstName = authState.user!.firstName!;
    } else if (authState.user?.fullName != null &&
        authState.user!.fullName!.isNotEmpty) {
      // Extract first name from full name if firstName is not available
      firstName = authState.user!.fullName!.split(' ').first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Welcome Back, $firstName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 8),
            const Text('😊', style: TextStyle(fontSize: 24)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          formattedDate,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildProgressAndMetricsSection(WidgetRef ref) {
    // Commented out tab selection - using default 'week' filter
    // final selectedTab = ref.watch(selectedTabProvider);
    // final filterMap = {0: 'day', 1: 'week', 2: 'month'};
    // final currentFilter = filterMap[selectedTab];
    final currentFilter = 'week'; // Default filter
    final dashboardStatsAsync = ref.watch(
      dashboardStatsProvider(currentFilter),
    );

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Track Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          // Commented out tab buttons for Day/Week/Month filter
          // Container(
          //   decoration: BoxDecoration(
          //     color: const Color(0xFFF5F5F5),
          //     borderRadius: BorderRadius.circular(10),
          //   ),
          //   padding: const EdgeInsets.all(4),
          //   child: Row(
          //     children: [
          //       _buildTabButton(ref, 'Day', 0, selectedTab),
          //       _buildTabButton(ref, 'Week', 1, selectedTab),
          //       _buildTabButton(ref, 'Month', 2, selectedTab),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 20),
          dashboardStatsAsync.when(
            data: (stats) => GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildMetricCard(
                  icon: Icons.description_outlined,
                  title: 'Resumes Generated',
                  value: stats.data?.itemCount?.totalResumes?.toString() ?? '0',
                ),
                _buildMetricCard(
                  icon: Icons.work_outline,
                  title: 'Job Applications',
                  value: '0',
                ),
                _buildMetricCard(
                  icon: Icons.groups_outlined,
                  title: 'Interviews',
                  value:
                      stats.data?.itemCount?.totalInterviews?.toString() ?? '0',
                ),
                _buildMetricCard(
                  icon: Icons.history,
                  title: 'Activities',
                  value:
                      stats.data?.itemCount?.activitiesCount?.toString() ?? '0',
                ),
              ],
            ),
            loading: () => GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: List.generate(4, (index) => _buildMetricCardShimmer()),
            ),
            error: (error, _) => GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: List.generate(
                4,
                (index) => Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '--',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    WidgetRef ref,
    String label,
    int index,
    int selectedTab,
  ) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(selectedTabProvider.notifier).state = index;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(WidgetRef ref) {
    // Commented out tab selection - using default 'week' filter
    // final selectedTab = ref.watch(selectedTabProvider);
    // final filterMap = {0: 'day', 1: 'week', 2: 'month'};
    // final currentFilter = filterMap[selectedTab];
    final currentFilter = 'week'; // Default filter
    final dashboardStatsAsync = ref.watch(
      dashboardStatsProvider(currentFilter),
    );

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          dashboardStatsAsync.when(
            data: (stats) {
              final items = stats.data?.items ?? [];
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No recent activities',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }
              return Column(
                children: items.take(6).map((item) {
                  final index = items.indexOf(item);
                  final isLast = index == items.length - 1 || index == 5;
                  final iconPath = item.type == 'resume'
                      ? 'assets/icons/resume.png'
                      : 'assets/icons/session.png';

                  return _buildActivityItem(
                    title: item.title ?? 'Unknown',
                    subtitle: item.activityTypeDisplay ?? item.subTitle ?? '',
                    timeAgo: DateHelpers.getTimeAgo(
                      item.timestamp ?? item.createdAt ?? '',
                    ),
                    iconPath: iconPath,
                    showDivider: !isLast,
                  );
                }).toList(),
              );
            },
            loading: () => Column(
              children: List.generate(
                3,
                (index) => _buildActivityItemShimmer(showDivider: index < 2),
              ),
            ),
            error: (error, _) => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Text(
                  'Failed to load activities',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String timeAgo,
    required String iconPath,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeAgo,
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
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
      ],
    );
  }

  Widget _buildMetricCardShimmer() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItemShimmer({bool showDivider = true}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 60,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
      ],
    );
  }
}
