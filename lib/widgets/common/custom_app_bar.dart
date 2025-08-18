import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        Image.asset('assets/icons/logo-fox-on-left.png', height: 32),
        const SizedBox(width: 8),
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

  static Widget premiumBadge() {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.workspace_premium,
        color: Color(0xFFFFB74D),
        size: 24,
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
