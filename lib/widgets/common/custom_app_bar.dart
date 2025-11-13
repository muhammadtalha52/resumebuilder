import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final Color backgroundColor;
  final double elevation;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.backgroundColor = AppColors.white,
    this.elevation = 0,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      scrolledUnderElevation: 0.0,
      toolbarHeight: 56,
      automaticallyImplyLeading: false,
      leading: leading,
      title: title,
      centerTitle: centerTitle,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

// Commonly used app bar widgets
class AppBarWidgets {
  AppBarWidgets._();

  static Widget foxLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/icons/logo-fox-on-left.png', height: 35),
        const SizedBox(width: 8),
      ],
    );
  }

  static Widget foxWithTitle({required String title}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/icons/fox-mascot.png', height: 32),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 26),
        ),
      ],
    );
  }

  static Widget foxWithSmallTitle({required String title}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/icons/fox-mascot.png', height: 32),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ],
    );
  }

  static Widget backButton({VoidCallback? onPressed}) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: onPressed ?? () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.only(left: 20),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }

  static Widget premiumBadge({BuildContext? context}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () {
          if (context != null) {
            context.push('/usage');
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/crown.png', width: 28, height: 28),
            const Text(
              'View Credits',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget historyButton({VoidCallback? onPressed}) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.history, color: AppColors.textSecondary, size: 30),
    );
  }
}

// Custom app bar with back navigation
class BackNavigationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showFoxIcon;

  const BackNavigationAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
    this.showFoxIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.scaffold,
      elevation: 0,
      leading: IconButton(
        onPressed: onBackPressed ?? () => context.pop(),
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.textPrimary,
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showFoxIcon) ...[
            Image.asset('assets/icons/fox-mascot.png', height: 35),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
