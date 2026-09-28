import 'dart:io';

import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/ai_consent_service.dart';
import '../../utils/url_launcher_utils.dart';

/// A reusable one-time consent popup for third-party AI data sharing disclosure,
/// required for Apple App Store compliance (Guideline 5.1.1/5.1.2).
///
/// This dialog explains third-party voice/transcript processing before microphone permission is requested.
class AIConsentDialog extends StatelessWidget {
  final bool isResume;
  const AIConsentDialog({super.key, this.isResume = false});

  /// Static helper to check and show the consent dialog if required.
  ///
  /// - Returns `true` on Android immediately without showing any UI or checking consent.
  /// - On iOS/iPadOS, returns `true` if consent was already given.
  /// - If not yet given on iOS/iPadOS, presents the dialog and returns `true` if the user taps "I Agree",
  ///   or `false` if the user taps "Cancel".
  static Future<bool> showIfNeeded(BuildContext context, {bool isResume = false}) async {
    // NOTE: Temporarily commented out for testing so you can see it on Android!
    // if (!Platform.isIOS) {
    //   return true; // Android is completely bypassed
    // }

    final hasConsent = await AIConsentService.hasConsent(isResume: isResume);
    if (hasConsent) {
      return true;
    }

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AIConsentDialog(isResume: isResume),
    );

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    // Brand purple fallback (#3C3489) if not matching theme
    const brandPurple = Color(0xFF3C3489);
    final primaryColor = colorScheme.primary == Colors.transparent
        ? brandPurple
        : colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            // Mascot / Fox icon at top
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                'assets/icons/fox-mascot.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.psychology_outlined,
                  size: 36,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Before You Start',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ) ??
                  TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // Body
            Text(
              isResume 
                ? 'To craft your professional resume, SkillResy sends your profile data to OpenAI, which securely processes and formats your tailored resume.'
                : 'To coach you during the interview, SkillResy sends your microphone audio to AssemblyAI, which turns it into text, and that text to OpenAI, which writes the questions and feedback you see. We do not keep an audio recording — only the written transcript, in your account.',
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14.5,
                height: 1.45,
                color: isDark
                    ? Colors.white70
                    : AppColors.textPrimary.withValues(alpha: 0.8),
              ) ??
                  TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: isDark
                        ? Colors.white70
                        : AppColors.textPrimary.withValues(alpha: 0.8),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Privacy Policy Link
            TextButton.icon(
              onPressed: () => UrlLauncherUtils.launchPrivacyPolicy(),
              icon: Icon(
                Icons.privacy_tip_outlined,
                size: 15,
                color: primaryColor,
              ),
              label: Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  decoration: TextDecoration.underline,
                  decorationColor: primaryColor,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons (Cancel / I Agree)
            Row(
              children: [
                // Reject Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await AIConsentService.acceptConsent(isResume: isResume, accepted: false);
                      if (context.mounted) {
                        Navigator.of(context).pop(false);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : AppColors.greyDark,
                      side: BorderSide(
                        color: isDark ? Colors.white24 : AppColors.border,
                        width: 1.2,
                      ),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Agree Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await AIConsentService.acceptConsent(isResume: isResume);
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Agree',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
