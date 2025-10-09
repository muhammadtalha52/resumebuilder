import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skillresy/utils/snackbar_utils.dart';

import '../../constants/app_colors.dart';
import '../../models/student_signup_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_signup_provider.dart';
import '../../widgets/common/fox_message_card.dart';
import 'account_creation_loading_screen.dart';
import 'student_step1_basic_info.dart';
import 'student_step2_academic_info.dart';

class StudentOnboardingStepScreen extends ConsumerStatefulWidget {
  final int stepNumber;

  const StudentOnboardingStepScreen({super.key, required this.stepNumber});

  @override
  ConsumerState<StudentOnboardingStepScreen> createState() =>
      _StudentOnboardingStepScreenState();
}

class _StudentOnboardingStepScreenState
    extends ConsumerState<StudentOnboardingStepScreen> {
  final Map<int, Map<String, dynamic>> stepConfig = {
    1: {
      'title': 'Step 1: Basic Information',
      'icon': '👤',
      'iconColor': AppColors.primary,
      'progress': 0.5,
      'foxTitle': 'Tell Us About You',
      'foxSubtitle': 'Start with the basics.',
    },
    2: {
      'title': 'Step 2: Academic Information',
      'icon': '🎓',
      'iconColor': AppColors.success,
      'progress': 1.0,
      'foxTitle': 'Your Education',
      'foxSubtitle': 'Share your academic background.',
    },
  };

  Widget _buildStepContent() {
    switch (widget.stepNumber) {
      case 1:
        return StudentStep1BasicInfo(onNext: _handleNext);
      case 2:
        return StudentStep2AcademicInfo(onNext: _handleNext);
      default:
        return const Center(child: Text('Invalid step'));
    }
  }

  void _handleNext() async {
    if (widget.stepNumber < 2) {
      ref.read(studentSignupProvider.notifier).nextStep();
      context.go('/student-signup/step/${widget.stepNumber + 1}');
    } else {
      // Complete student signup - call API and navigate to loading screen
      await _completeStudentSignup();
    }
  }

  Future<void> _completeStudentSignup() async {
    final studentSignupState = ref.read(studentSignupProvider);
    final authNotifier = ref.read(authProvider.notifier);

    // Create a GlobalKey to control the loading screen animation
    final loadingScreenKey = GlobalKey<AccountCreationLoadingScreenState>();

    // Navigate to loading screen
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AccountCreationLoadingScreen(
              key: loadingScreenKey,
              isStudent: true,
              onAnimationComplete: () {
                // Navigate to home screen after animation completes
                if (mounted) {
                  context.go('/home');
                }
              },
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    try {
      // Create signup request from student signup state
      final signupRequest = StudentSignupRequest.fromStudentSignupState(
        studentSignupState,
      );

      // Call signup API
      await authNotifier.signUpStudent(signupRequest);

      // Check if we're still mounted before showing UI
      if (!mounted) return;

      // Trigger the completion animation
      loadingScreenKey.currentState?.completeAnimation();
    } catch (e) {
      // Handle error - pop loading screen and show error
      if (!mounted) return;

      Navigator.of(context).pop();

      // Show error message
      showErrorSnackBar(
        context: context,
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void _handleBack() {
    if (widget.stepNumber > 1) {
      ref.read(studentSignupProvider.notifier).previousStep();
      context.go('/student-signup/step/${widget.stepNumber - 1}');
    } else {
      context.go('/user-type-selection');
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
                                // Progress indicator - 2 separate lines for each step
                                Row(
                                  children: List.generate(2, (index) {
                                    final isCompleted =
                                        index < widget.stepNumber;
                                    final isLast = index == 1;

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
