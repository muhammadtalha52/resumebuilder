import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillresy/constants/app_colors.dart';
import 'package:skillresy/constants/app_sizes.dart';
import 'package:skillresy/providers/user_type_provider.dart';
import 'package:skillresy/widgets/common/custom_button.dart';

class UserTypeSelectionScreen extends ConsumerStatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  ConsumerState<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState
    extends ConsumerState<UserTypeSelectionScreen> {
  String? _selectedUserType;

  void _handleContinue() {
    if (_selectedUserType != null) {
      ref.read(userTypeProvider.notifier).state = _selectedUserType!;

      // Navigate based on user type
      if (_selectedUserType == 'student') {
        context.go('/student-signup');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= AppSizes.tabletBreakpoint;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background pattern
            Positioned.fill(
              child: Image.asset(
                'assets/icons/background.png',
                fit: BoxFit.cover,
              ),
            ),
            // Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? AppSizes.paddingXL : 5),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 600 : double.infinity,
                    ),
                    child: Column(
                      children: [
                        // Card
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusL,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.paddingM),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // SkillResy Logo
                                Image.asset(
                                  'assets/icons/logo-fox-on-left.png',
                                  height: isTablet ? 150 : 120,
                                  width: isTablet ? 350 : 300,
                                ),

                                const SizedBox(height: AppSizes.spaceS),

                                // Title
                                Text(
                                  'Select Your Role',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: AppSizes.spaceS),

                                // Subtitle
                                Text(
                                  'Choose the option that best describes you',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSizes.spaceXL),

                                // User Type Cards
                                Column(
                                  children: [
                                    // Candidate Card
                                    _buildUserTypeCard(
                                      context: context,
                                      type: 'candidate',
                                      icon: Icons.work_outline,
                                      title: 'Candidate',
                                      description:
                                          'I\'m actively seeking employment opportunities',
                                      isSelected:
                                          _selectedUserType == 'candidate',
                                      onTap: () {
                                        setState(() {
                                          _selectedUserType = 'candidate';
                                        });
                                      },
                                    ),
                                    const SizedBox(height: AppSizes.spaceM),
                                    // Student Card
                                    _buildUserTypeCard(
                                      context: context,
                                      type: 'student',
                                      icon: Icons.school_outlined,
                                      title: 'Student',
                                      description:
                                          'I\'m currently pursuing my education',
                                      isSelected:
                                          _selectedUserType == 'student',
                                      onTap: () {
                                        setState(() {
                                          _selectedUserType = 'student';
                                        });
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: AppSizes.spaceXL),

                                // Continue Button
                                CustomButton(
                                  text: 'Continue',
                                  onPressed: _selectedUserType != null
                                      ? _handleContinue
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spaceL),

                        // Back to Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            TextButton(
                              onPressed: () {
                                context.go('/login');
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeCard({
    required BuildContext context,
    required String type,
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.accent.withOpacity(0.05)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withOpacity(0.1)
                    : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSizes.spaceM),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceXS),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Selection Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
