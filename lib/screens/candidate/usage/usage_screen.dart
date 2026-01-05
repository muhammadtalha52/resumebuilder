import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../providers/usage_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/invite_friends_card.dart';

class UsageScreen extends ConsumerStatefulWidget {
  const UsageScreen({super.key});

  @override
  ConsumerState<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends ConsumerState<UsageScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch usage data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usageProvider.notifier).fetchUsageAllocation();
    });
  }

  @override
  void activate() {
    super.activate();
    // Refresh usage data when coming back to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usageProvider.notifier).fetchUsageAllocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usageState = ref.watch(usageProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: CustomAppBar(
        leading: AppBarWidgets.backButton(onPressed: () => context.pop()),
        title: AppBarWidgets.foxWithSmallTitle(title: 'Your Usage'),
      ),
      body: Stack(
        children: [
          // Techy background
          Positioned.fill(
            child: Image.asset(
              'assets/icons/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content
          LayoutBuilder(
            builder: (context, constraints) {
              // Show content if available, otherwise show error/empty state
              if (usageState.usageAllocation != null) {
                return _buildUsageContent(context, constraints);
              } else if (usageState.error != null && !usageState.isLoading) {
                return _buildErrorState(usageState.error!);
              } else if (!usageState.isLoading) {
                return _buildEmptyState();
              } else {
                // First time loading with no data
                return _buildLoadingState();
              }
            },
          ),
          // Loading indicator - shows on top when refreshing
          if (usageState.isLoading && usageState.usageAllocation != null)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 64),
              const SizedBox(height: AppSizes.paddingM),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),
              ElevatedButton(
                onPressed: () {
                  ref.read(usageProvider.notifier).fetchUsageAllocation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
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
          child: const Text(
            'No usage data available',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildUsageContent(BuildContext context, BoxConstraints constraints) {
    final usage = ref.watch(usageProvider).usageAllocation!;
    final isStudent = ref.watch(isStudentProvider);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
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
                // Invite friends card
                InviteFriendsCard(isStudent: isStudent),
                const SizedBox(height: 16),

                // User info section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usage.userEmail,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Divider
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 20),

                // Available title
                const Text(
                  'Available',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Usage cards - show different features based on user type
                if (!isStudent) ...[
                  // Candidate features
                  _buildUsageCard(
                    icon: Icons.description_outlined,
                    title: 'Resumes',
                    count: usage.remainingResumeCount,
                    color: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 12),
                  _buildUsageCard(
                    icon: Icons.chat_bubble_outline,
                    title: 'Interviews',
                    count: usage.remainingInterviewCount,
                    color: const Color(0xFF2196F3),
                  ),
                ] else ...[
                  // Student features
                  _buildUsageCard(
                    icon: Icons.quiz_outlined,
                    title: 'Quizzes',
                    count: usage.remainingQuizCount,
                    color: const Color(0xFFFF9800),
                  ),
                  const SizedBox(height: 12),
                  _buildUsageCard(
                    icon: Icons.upload_file_outlined,
                    title: 'Document Uploads',
                    count: usage.remainingDocumentUploadCount,
                    color: const Color(0xFF9C27B0),
                  ),
                ],

                const SizedBox(height: 20),

                // Divider
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 16),

                // Get more button
                CustomButton(
                  text: 'Buy More',
                  onPressed: () async {
                    // Route to correct plans screen based on user type
                    final plansRoute = isStudent ? '/student/plans' : '/plans';
                    await context.push(plansRoute);
                    // Refresh usage data when returning from plans
                    if (mounted) {
                      ref.read(usageProvider.notifier).fetchUsageAllocation();
                    }
                  },
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsageCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count remaining',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
