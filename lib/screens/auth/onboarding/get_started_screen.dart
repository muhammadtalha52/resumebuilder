import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillresy/constants/app_colors.dart';
import 'package:skillresy/constants/app_sizes.dart';
import 'package:skillresy/providers/education_data_provider.dart';

class GetStartedScreen extends ConsumerStatefulWidget {
  const GetStartedScreen({super.key});

  @override
  ConsumerState<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends ConsumerState<GetStartedScreen> {
  @override
  void initState() {
    super.initState();
    // Pre-fetch education data in the background
    // This will cache the data in the provider for later use
    Future.microtask(() {
      ref.read(educationDataProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
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
