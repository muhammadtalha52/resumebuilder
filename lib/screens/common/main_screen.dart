import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../candidate/interview/meetings_screen.dart';
import '../candidate/profile/profile_screen.dart';
import '../candidate/dashboard_screen.dart';
import '../candidate/resume/resume_screen.dart';
import '../student/student_dashboard_screen.dart';
import '../student/student_profile_screen.dart';
import '../student/workspace_screen.dart';

// Provider to track current navigation index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final isStudent = ref.watch(isStudentProvider);

    // Student screens: Dashboard, Workspace, Profile
    // Candidate screens: Dashboard, Resumes, Meetings, Profile
    final screens = isStudent
        ? const [
            StudentDashboardScreen(),
            WorkspaceScreen(),
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
      bottomNavigationBar: _buildBottomNavigationBar(ref, safeIndex, isStudent),
    );
  }

  Widget _buildBottomNavigationBar(
    WidgetRef ref,
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
                ? _buildStudentNavItems(ref, currentIndex)
                : _buildCandidateNavItems(ref, currentIndex),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStudentNavItems(WidgetRef ref, int currentIndex) {
    return [
      _buildNavItem(
        ref: ref,
        index: 0,
        currentIndex: currentIndex,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
      ),
      _buildNavItem(
        ref: ref,
        index: 1,
        currentIndex: currentIndex,
        icon: Icons.workspace_premium_outlined,
        activeIcon: Icons.workspace_premium,
        label: 'Workspace',
      ),
      _buildNavItem(
        ref: ref,
        index: 2,
        currentIndex: currentIndex,
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
      ),
    ];
  }

  List<Widget> _buildCandidateNavItems(WidgetRef ref, int currentIndex) {
    return [
      _buildNavItem(
        ref: ref,
        index: 0,
        currentIndex: currentIndex,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
      ),
      _buildNavItem(
        ref: ref,
        index: 1,
        currentIndex: currentIndex,
        icon: Icons.description_outlined,
        activeIcon: Icons.description,
        label: 'Resumes',
        isCustomIcon: true,
        customIconPath: 'assets/icons/resume.png',
      ),
      _buildNavItem(
        ref: ref,
        index: 2,
        currentIndex: currentIndex,
        icon: Icons.headset_mic_outlined,
        activeIcon: Icons.headset_mic,
        label: 'Meetings',
        isCustomIcon: true,
        customIconPath: 'assets/icons/session.png',
      ),
      _buildNavItem(
        ref: ref,
        index: 3,
        currentIndex: currentIndex,
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
      ),
    ];
  }

  Widget _buildNavItem({
    required WidgetRef ref,
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
      onTap: () {
        ref.read(navigationIndexProvider.notifier).state = index;
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
