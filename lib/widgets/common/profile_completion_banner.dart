import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../screens/common/main_screen.dart';

class ProfileCompletionBanner extends ConsumerWidget {
  final bool isProfileScreen;

  const ProfileCompletionBanner({super.key, this.isProfileScreen = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isStudent = ref.watch(isStudentProvider);

    final completionPercentage = user?.profileCompletionPercentage ?? 0;

    // Hide banner for students (only show for candidates)
    if (isStudent) {
      return const SizedBox.shrink();
    }

    // Hide banner if profile is 100% complete
    if (completionPercentage >= 100) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: isProfileScreen ? null : () => _navigateToProfile(ref, isStudent),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.gradientPurple1, AppColors.gradientPurple2],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Progress indicator
            SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: completionPercentage / 100,
                    strokeWidth: 3,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                  Text(
                    '$completionPercentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isProfileScreen
                        ? 'Profile $completionPercentage% Complete'
                        : 'Complete Your Profile',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isProfileScreen
                        ? _getProfileScreenMessage(completionPercentage)
                        : _getEncouragingMessage(completionPercentage),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon (only show when not on profile screen)
            if (!isProfileScreen)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getEncouragingMessage(int percentage) {
    return 'Complete your profile to stand out to recruiters!';
  }

  String _getProfileScreenMessage(int percentage) {
    return 'Fill in the sections below to get noticed!';
  }

  void _navigateToProfile(WidgetRef ref, bool isStudent) {
    // Profile tab index: 3 for candidates, 2 for students
    final profileIndex = isStudent ? 2 : 3;
    ref.read(navigationIndexProvider.notifier).state = profileIndex;
  }
}
