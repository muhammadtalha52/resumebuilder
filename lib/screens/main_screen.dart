import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import 'dashboard/dashboard_screen.dart';

// Provider to track current navigation index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          DashboardScreen(),
          _PlaceholderScreen(title: 'Resume'),
          _PlaceholderScreen(title: 'Interview'),
          _PlaceholderScreen(title: 'Profile'),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(ref, currentIndex),
    );
  }

  Widget _buildBottomNavigationBar(WidgetRef ref, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
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
                label: 'Resume',
              ),
              _buildNavItem(
                ref: ref,
                index: 2,
                currentIndex: currentIndex,
                icon: Icons.headset_mic_outlined,
                activeIcon: Icons.headset_mic,
                label: 'Interview',
              ),
              _buildNavItem(
                ref: ref,
                index: 3,
                currentIndex: currentIndex,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required WidgetRef ref,
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = currentIndex == index;

    return InkWell(
      onTap: () {
        ref.read(navigationIndexProvider.notifier).state = index;
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder screen for empty pages
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: Text(
          '$title Screen\nComing Soon',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
