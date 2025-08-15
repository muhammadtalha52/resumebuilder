import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/signup_request.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/common/fox_message_card.dart';
import '../account_creation_loading_screen.dart';
import 'steps/step1_personal_details.dart';
import 'steps/step2_career_goals.dart';
import 'steps/step3_education.dart';
import 'steps/step4_work_experience.dart';
import 'steps/step5_skills.dart';
import 'steps/step6_optional_info.dart';

class OnboardingStepScreen extends ConsumerStatefulWidget {
  final int stepNumber;

  const OnboardingStepScreen({super.key, required this.stepNumber});

  @override
  ConsumerState<OnboardingStepScreen> createState() =>
      _OnboardingStepScreenState();
}

class _OnboardingStepScreenState extends ConsumerState<OnboardingStepScreen> {
  final Map<int, Map<String, dynamic>> stepConfig = {
    1: {
      'title': 'Step 1: Personal Details',
      'icon': '👤',
      'iconColor': AppColors.primary,
      'progress': 0.17,
      'foxTitle': 'Tell Us About You',
      'foxSubtitle': 'Start with the basics.',
    },
    2: {
      'title': 'Step 2: Career Goals',
      'icon': '🎯',
      'iconColor': AppColors.error,
      'progress': 0.33,
      'foxTitle': 'Your Career Goals',
      'foxSubtitle': 'Help us tailor your journey.',
    },
    3: {
      'title': 'Step 3: Education',
      'icon': '🎓',
      'iconColor': AppColors.success,
      'progress': 0.5,
      'foxTitle': 'Your Education',
      'foxSubtitle': 'Share your academic background.',
    },
    4: {
      'title': 'Step 4: Work Experience',
      'icon': '💼',
      'iconColor': AppColors.info,
      'progress': 0.67,
      'foxTitle': 'Your Experience',
      'foxSubtitle': 'Highlight your past roles.',
    },
    5: {
      'title': 'Step 5: Skills & Tools',
      'icon': '🛠️',
      'iconColor': AppColors.warning,
      'progress': 0.83,
      'foxTitle': 'Your Skills',
      'foxSubtitle': 'What are you great at?',
    },
    6: {
      'title': 'Step 6: Optional Info',
      'icon': '🌍',
      'iconColor': AppColors.accent,
      'progress': 1.0,
      'foxTitle': 'Additional Info',
      'foxSubtitle': 'Add more if you\'d like.',
    },
  };

  Widget _buildStepContent() {
    switch (widget.stepNumber) {
      case 1:
        return Step1PersonalDetails(onNext: _handleNext);
      case 2:
        return Step2CareerGoals(onNext: _handleNext);
      case 3:
        return Step3Education(onNext: _handleNext);
      case 4:
        return Step4WorkExperience(onNext: _handleNext);
      case 5:
        return Step5Skills(onNext: _handleNext);
      case 6:
        return Step6OptionalInfo(onNext: _handleNext);
      default:
        return const Center(child: Text('Invalid step'));
    }
  }

  void _handleNext() async {
    if (widget.stepNumber < 6) {
      context.go('/onboarding/step/${widget.stepNumber + 1}');
    } else {
      // Complete onboarding by calling signup API
      await _completeOnboardingWithSignup();
    }
  }

  Future<void> _completeOnboardingWithSignup() async {
    final onboardingState = ref.read(onboardingProvider);
    final authNotifier = ref.read(authProvider.notifier);

    // Check if we're mounted before showing any UI
    if (!mounted) return;

    // Keep a reference to the loading screen
    GlobalKey<AccountCreationLoadingScreenState>? loadingScreenKey =
        GlobalKey<AccountCreationLoadingScreenState>();

    // Navigate to loading screen
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AccountCreationLoadingScreen(
              key: loadingScreenKey,
              onAnimationComplete: () {
                // Navigate to home after animation completes
                if (mounted) {
                  Navigator.of(context).pop();
                  context.go('/home');
                }
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    try {
      // Create signup request from onboarding state
      final signupRequest = SignUpRequest.fromOnboardingState(onboardingState);

      // Call signup API using the DTO
      await authNotifier.signUpFromOnboarding(signupRequest);

      // Complete onboarding state
      ref.read(onboardingProvider.notifier).completeOnboarding();

      // Check if we're still mounted before showing UI
      if (!mounted) return;

      // Trigger the completion animation
      loadingScreenKey.currentState?.completeAnimation();
    } catch (e) {
      // Check if we're still mounted before showing UI
      if (!mounted) return;

      // Pop the loading screen
      Navigator.of(context).pop();

      // Get the specific error message from auth state or use the exception message
      final authState = ref.read(authProvider);
      final errorMessage =
          authState.error ?? e.toString().replaceAll('Exception: ', '');

      // Show specific error message from API
      showErrorSnackBar(
        context: context,
        message: errorMessage.isEmpty
            ? 'Failed to create account. Please try again.'
            : errorMessage,
      );
    }
  }

  void _handleBack() {
    if (widget.stepNumber > 1) {
      context.go('/onboarding/step/${widget.stepNumber - 1}');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = stepConfig[widget.stepNumber]!;
    final isEmoji = config['icon'] is String;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return GestureDetector(
      onTap: () {
        // Unfocus when tapping outside text fields
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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 20 : 6),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 600 : double.infinity,
                    ),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Header with back button and progress
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              10.0,
                              15.0,
                              10.0,
                              0.0,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.grey.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    onPressed: _handleBack,
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: AppColors.black,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (isEmoji)
                                  Text(
                                    config['icon'],
                                    style: const TextStyle(fontSize: 24),
                                  )
                                else
                                  Icon(
                                    config['icon'],
                                    color: AppColors.textPrimary,
                                    size: 24,
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    config['title'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                // Progress indicator - 6 separate lines for each step
                                Row(
                                  children: List.generate(6, (index) {
                                    final isCompleted =
                                        index < widget.stepNumber;
                                    final isLast = index == 5;

                                    return Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: isCompleted
                                                    ? AppColors.primary
                                                    : AppColors.greyLight,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                          if (!isLast) const SizedBox(width: 4),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 24),
                                // Fox mascot with card
                                FoxMessageCard(
                                  title: config['foxTitle'],
                                  subtitle: config['foxSubtitle'],
                                ),
                                const SizedBox(height: 32),
                                // Step content
                                _buildStepContent(),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      ),
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
}
