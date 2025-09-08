import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../providers/auth_provider.dart';

final selectedTabProvider = StateProvider<int>((ref) => 1);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildWelcomeSection(ref),
                const SizedBox(height: 10),
                _buildProgressAndMetricsSection(ref),
                const SizedBox(height: 24),
                _buildRecentActivitySection(),
                const SizedBox(height: 20),
              ],
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
    final selectedTab = ref.watch(selectedTabProvider);

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
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildTabButton(ref, 'Day', 0, selectedTab),
                _buildTabButton(ref, 'Week', 1, selectedTab),
                _buildTabButton(ref, 'Month', 2, selectedTab),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
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
                value: '15',
              ),
              _buildMetricCard(
                icon: Icons.work_outline,
                title: 'Job Applications',
                value: '14',
              ),
              _buildMetricCard(
                icon: Icons.groups_outlined,
                title: 'Interviews',
                value: '05',
              ),
              _buildMetricCard(
                icon: Icons.history,
                title: 'Interview History',
                value: '18',
              ),
            ],
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

  Widget _buildRecentActivitySection() {
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
          _buildActivityItem(
            title: 'Senior Unity Developer',
            subtitle: 'Resume Generation',
            timeAgo: '1 day ago',
            iconPath: 'assets/icons/resume.png',
            showDivider: true,
          ),
          _buildActivityItem(
            title: 'Software Engineer',
            subtitle: 'Interview Assistant',
            timeAgo: '1 day ago',
            iconPath: 'assets/icons/session.png',
            showDivider: true,
          ),
          _buildActivityItem(
            title: 'DevOps Engineer',
            subtitle: 'Job Interview',
            timeAgo: '1 day ago',
            iconPath: 'assets/icons/session.png',
            showDivider: true,
          ),
          _buildActivityItem(
            title: 'Senior Unity Developer',
            subtitle: 'Resume Generation',
            timeAgo: '1 day ago',
            iconPath: 'assets/icons/resume.png',
            showDivider: true,
          ),
          _buildActivityItem(
            title: 'Software Engineer',
            subtitle: 'Interview Assistant',
            timeAgo: '1 day ago',
            iconPath: 'assets/icons/session.png',
            showDivider: true,
          ),
          _buildActivityItem(
            title: 'DevOps Engineer',
            subtitle: 'Job Interview',
            timeAgo: '1 day ago',
            iconPath: 'assets/icons/session.png',
            showDivider: false,
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
}
