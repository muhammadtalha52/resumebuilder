import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../../utils/url_launcher_utils.dart';

/// Reusable legal footer with Terms of Use (EULA) and Privacy Policy links.
///
/// Required by Apple App Store Guideline 3.1.2(c) on all subscription screens.
class SubscriptionLegalFooter extends StatelessWidget {
  /// Whether to use light-colored text (for gradient backgrounds).
  final bool lightText;

  const SubscriptionLegalFooter({
    super.key,
    this.lightText = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = lightText
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.grey.shade600;
    final dividerColor = lightText
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.grey.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (Platform.isIOS) {
                UrlLauncherUtils.launchExternalUrl(
                  'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
                );
              } else {
                UrlLauncherUtils.launchTermsOfUse();
              }
            },
            child: Text(
              'Terms of Use (EULA)',
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: textColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '|',
              style: TextStyle(
                fontSize: 12,
                color: dividerColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              UrlLauncherUtils.launchPrivacyPolicy();
            },
            child: Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
