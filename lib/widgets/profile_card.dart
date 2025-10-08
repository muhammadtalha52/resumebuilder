import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class ProfileCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onEdit;
  final bool showDividers;

  const ProfileCard({
    super.key,
    required this.title,
    required this.child,
    required this.onEdit,
    this.showDividers = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Image.asset(
                    'assets/icons/edit-line.png',
                    width: 25,
                    height: 25,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (showDividers)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.inputBorder, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: child,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: child,
            ),
        ],
      ),
    );
  }
}
