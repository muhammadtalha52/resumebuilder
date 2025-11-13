import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/custom_button.dart';

/// Shows a professional dialog when email already exists
/// Returns true if user wants to try different email, false otherwise
Future<bool?> showEmailExistsDialog({
  required BuildContext context,
  required String email,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => EmailExistsDialog(email: email),
  );
}

class EmailExistsDialog extends StatelessWidget {
  final String email;

  const EmailExistsDialog({super.key, required this.email});

  /// Parse email to extract username and domain for suggestions
  Map<String, String> _parseEmail(String email) {
    final parts = email.split('@');
    if (parts.length == 2) {
      return {'username': parts[0], 'domain': parts[1]};
    }
    return {'username': email, 'domain': 'gmail.com'};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final emailParts = _parseEmail(email);
    final username = emailParts['username']!;
    final domain = emailParts['domain']!;

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
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.mail_outline,
                color: colorScheme.onPrimary,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Email Already Exists',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Main message
            Text(
              'Use another email or try an alias:',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Email suggestion
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '$username+1@$domain',
                    style: textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Emails arrive in your main inbox',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action button
            CustomButton(
              text: 'Got it',
              onPressed: () => Navigator.of(context).pop(false),
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}
