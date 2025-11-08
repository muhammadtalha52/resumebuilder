import 'package:flutter/material.dart';

/// Single-button notification dialog for informational messages
/// Use this when you only need to notify the user without requiring a choice
class NotificationDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconBackgroundColor;
  final String buttonText;
  final VoidCallback onTap;
  final Color? buttonColor;
  final Color? buttonTextColor;

  const NotificationDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconBackgroundColor,
    this.buttonText = 'OK',
    required this.onTap,
    this.buttonColor,
    this.buttonTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon (if provided)
            if (icon != null) ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBackgroundColor ?? colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 24),
            ],

            // Title
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            // Subtitle (if provided)
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),

            // Single button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: buttonColor ?? colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: buttonTextColor ?? Colors.white,
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

/// Helper function to show notification dialog with single button
Future<void> showNotificationDialog({
  required BuildContext context,
  required String title,
  String? subtitle,
  IconData? icon,
  Color? iconBackgroundColor,
  String buttonText = 'OK',
  Color? buttonColor,
  Color? buttonTextColor,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => NotificationDialog(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconBackgroundColor: iconBackgroundColor,
      buttonText: buttonText,
      buttonColor: buttonColor,
      buttonTextColor: buttonTextColor,
      onTap: () => Navigator.of(context).pop(),
    ),
  );
}
