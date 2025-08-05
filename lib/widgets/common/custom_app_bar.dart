import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';

enum AppBarType { dashboard, back }

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final AppBarType type;
  final String? title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showPremiumBadge;
  final Color backgroundColor;
  final double elevation;

  const CustomAppBar({
    super.key,
    this.type = AppBarType.back,
    this.title,
    this.actions,
    this.onBackPressed,
    this.showPremiumBadge = true,
    this.backgroundColor = Colors.transparent,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      toolbarHeight: 56,
      automaticallyImplyLeading: false,
      title: type == AppBarType.dashboard
          ? _buildDashboardTitle()
          : _buildBackTitle(context),
      actions: _buildActions(),
    );
  }

  Widget _buildDashboardTitle() {
    return Row(
      children: [
        Image.asset('assets/icons/logo-fox-on-left.png', height: 32),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBackTitle(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBackPressed ?? () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
        if (title != null) ...[
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions() {
    final List<Widget> actionWidgets = [];

    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    if (showPremiumBadge) {
      actionWidgets.add(
        Container(
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
        ),
      );
    }

    return actionWidgets;
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
