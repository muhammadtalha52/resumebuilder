import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/tour_strings.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stripe_subscription_provider.dart';
import '../../providers/iap_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/onboarding_funnel_service.dart';
import '../../widgets/tour/guided_tour_overlay.dart';
import '../../widgets/plans/paywall_modal.dart';
import '../candidate/interview/meetings_screen.dart';
import '../candidate/profile/profile_screen.dart';
import '../candidate/dashboard_screen.dart';
import '../candidate/resume/resume_screen.dart';
import '../student/student_dashboard_screen.dart';
import '../student/student_profile_screen.dart';
import '../student/study_space_screen.dart';

// Provider to track current navigation index
// Default to index 1 (Study Space for students, Resumes for candidates)
final navigationIndexProvider = StateProvider<int>((ref) => 1);

// Provider to force re-trigger guided tour on-demand from profile or settings
final forceTourTriggerProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // GlobalKeys for Guided Tour highlighting
  final GlobalKey _candDashboardKey = GlobalKey();
  final GlobalKey _candResumeKey = GlobalKey();
  final GlobalKey _candMeetingKey = GlobalKey();
  final GlobalKey _candProfileKey = GlobalKey();

  final GlobalKey _studDashboardKey = GlobalKey();
  final GlobalKey _studSpaceKey = GlobalKey();
  final GlobalKey _studProfileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isStudent = ref.read(isStudentProvider);
      // Pre-warm plans in background so Paywall opens instantly with zero delay
      ref.read(stripeSubscriptionProvider.notifier).loadData(role: isStudent ? 2 : 1);
      ref.read(iapProvider.notifier).loadPlansMapping();

      _checkAndLaunchFunnel();
    });
  }

  /// Evaluates whether the user should see the Guided Tour or Paywall Modal.
  /// Handles both New Users (registration) and Existing Users (next launch after release).
  Future<void> _checkAndLaunchFunnel() async {
    // Wait slightly so layout and keys are attached
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Refresh subscription to ensure up-to-date status
    try {
      await ref.read(stripeSubscriptionProvider.notifier).refreshSubscription();
    } catch (_) {}

    if (!mounted) return;

    final isStudent = ref.read(isStudentProvider);
    final hasActiveSub =
        ref.read(stripeSubscriptionProvider).hasActiveSubscription;

    // GOLDEN RULE: Never show tour or paywall to active plan or trialing users
    if (hasActiveSub) {
      debugPrint('[Funnel] User has active plan or trial — suppressing tour and paywall.');
      return;
    }

    // Check backend onboarding status (syncs with GET /api/auth/onboarding/ and local storage)
    // Applies to both New Users and Existing Users on their next launch after release
    final isTourDone =
        await OnboardingFunnelService.instance.fetchOnboardingStatusFromBackend();

    if (!mounted) return;

    if (!isTourDone) {
      _launchGuidedTour();
    } else {
      // 2. Tour already done -> Check 72h Cooldown & Session Cap for Paywall
      final canShow = await OnboardingFunnelService.instance
          .canShowPaywallModalAsync(hasActiveSubscription: hasActiveSub);
      if (canShow && mounted) {
        PaywallModal.show(
          context,
          isStudent: isStudent,
          triggerReason: 'no_plan',
        );
      }
    }
  }

  void _launchGuidedTour({bool force = false}) {
    final isStudent = ref.read(isStudentProvider);
    AnalyticsService.logTourStarted(audience: 'b2c');

    final keys = isStudent
        ? [
            _studDashboardKey,
            _studSpaceKey,
            _studProfileKey,
            _studDashboardKey,
          ]
        : [
            _candResumeKey,
            _candMeetingKey,
            _candProfileKey,
            _candDashboardKey,
          ];

    final steps =
        isStudent ? TourStrings.studentSteps : TourStrings.candidateSteps;

    GuidedTourOverlay.show(
      context: context,
      targetKeys: keys,
      steps: steps,
      onFinish: () async {
        await OnboardingFunnelService.instance.markTourCompleted();
        AnalyticsService.logTourCompleted(stepsCompleted: steps.length);

        // Immediately show Paywall modal if no active plan
        if (mounted && !ref.read(stripeSubscriptionProvider).hasActiveSubscription) {
          PaywallModal.show(
            context,
            isStudent: isStudent,
            triggerReason: 'post_tour',
          );
        }
      },
      onSkip: (step) async {
        await OnboardingFunnelService.instance.markTourCompleted();
        AnalyticsService.logTourSkipped(stepNumber: step);

        // Immediately show Paywall modal if no active plan
        if (mounted && !ref.read(stripeSubscriptionProvider).hasActiveSubscription) {
          PaywallModal.show(
            context,
            isStudent: isStudent,
            triggerReason: 'post_tour',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(forceTourTriggerProvider, (prev, next) {
      if (next > 0) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            _launchGuidedTour(force: true);
          }
        });
      }
    });

    final currentIndex = ref.watch(navigationIndexProvider);
    final isStudent = ref.watch(isStudentProvider);

    // Student screens: Dashboard, Study Space, Profile
    // Candidate screens: Dashboard, Resumes, Meetings, Profile
    final screens = isStudent
        ? const [
            StudentDashboardScreen(),
            StudySpaceScreen(),
            StudentProfileScreen(),
          ]
        : const [
            DashboardScreen(),
            ResumeScreen(),
            MeetingScreen(),
            ProfileScreen(),
          ];

    // Ensure index is within bounds for current screen list
    final maxIndex = screens.length - 1;
    final safeIndex = currentIndex > maxIndex ? 0 : currentIndex;

    // Reset to 0 if index is out of bounds
    if (currentIndex > maxIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationIndexProvider.notifier).state = 0;
      });
    }

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: _buildBottomNavigationBar(safeIndex, isStudent),
    );
  }

  Widget _buildBottomNavigationBar(
    int currentIndex,
    bool isStudent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: isStudent
                ? _buildStudentNavItems(currentIndex)
                : _buildCandidateNavItems(currentIndex),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStudentNavItems(int currentIndex) {
    return [
      _buildNavItem(
        key: _studDashboardKey,
        index: 0,
        currentIndex: currentIndex,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
      ),
      _buildNavItem(
        key: _studSpaceKey,
        index: 1,
        currentIndex: currentIndex,
        icon: Icons.folder_copy_outlined,
        activeIcon: Icons.folder_copy,
        label: 'Study Space',
      ),
      _buildNavItem(
        key: _studProfileKey,
        index: 2,
        currentIndex: currentIndex,
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
      ),
    ];
  }

  List<Widget> _buildCandidateNavItems(int currentIndex) {
    return [
      _buildNavItem(
        key: _candDashboardKey,
        index: 0,
        currentIndex: currentIndex,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
      ),
      _buildNavItem(
        key: _candResumeKey,
        index: 1,
        currentIndex: currentIndex,
        icon: Icons.description_outlined,
        activeIcon: Icons.description,
        label: 'Resumes',
        isCustomIcon: true,
        customIconPath: 'assets/icons/resume.png',
      ),
      _buildNavItem(
        key: _candMeetingKey,
        index: 2,
        currentIndex: currentIndex,
        icon: Icons.headset_mic_outlined,
        activeIcon: Icons.headset_mic,
        label: 'Meetings',
        isCustomIcon: true,
        customIconPath: 'assets/icons/session.png',
      ),
      _buildNavItem(
        key: _candProfileKey,
        index: 3,
        currentIndex: currentIndex,
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
      ),
    ];
  }

  Widget _buildNavItem({
    Key? key,
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool isCustomIcon = false,
    String? customIconPath,
  }) {
    final isActive = currentIndex == index;

    return InkWell(
      key: key,
      onTap: () {
        ref.read(navigationIndexProvider.notifier).state = index;

        // Because IndexedStack keeps widgets alive, ProfileScreen's initState
        // only runs once. We must explicitly trigger a refresh when the tab is tapped.
        if (label == 'Profile') {
          ref.read(authProvider.notifier).refreshUser();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              isCustomIcon && customIconPath != null
                  ? Image.asset(
                      customIconPath,
                      width: 24,
                      height: 24,
                      color: isActive ? AppColors.accent : AppColors.textLight,
                    )
                  : Icon(
                      isActive ? activeIcon : icon,
                      color: isActive ? AppColors.accent : AppColors.textLight,
                      size: 24,
                    ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppColors.accent : AppColors.textLight,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
