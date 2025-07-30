import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:skillresy/constants/app_colors.dart';
import 'package:skillresy/constants/app_sizes.dart';
import 'package:skillresy/widgets/common/custom_text_field.dart';

class GetStartedScreen extends ConsumerWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= AppSizes.tabletBreakpoint;

    return Scaffold(
      backgroundColor: const Color(0xFF00003D),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? AppSizes.paddingXL : AppSizes.paddingL,
            vertical: AppSizes.paddingXL,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Fox mascot
              Image.asset(
                'assets/icons/white-logo-fox-top.png',
                width: isTablet ? 180 : 190,
                height: isTablet ? 180 : 190,
              ),
              const SizedBox(height: AppSizes.spaceXL),
              // Title
              Text(
                "Let's Build Your Profile",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),

              Text(
                'This helps us personalize your\nexperience.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 4),
              // Start button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/onboarding/step/1');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentDark,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spaceL),
            ],
          ),
        ),
      ),
    );
  }
}
