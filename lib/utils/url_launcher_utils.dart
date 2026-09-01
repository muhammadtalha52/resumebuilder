import 'package:url_launcher/url_launcher.dart';

/// Utility class for launching external URLs
class UrlLauncherUtils {
  /// Opens an external URL in the device's default browser
  ///
  /// Returns true if the URL was successfully launched, false otherwise
  static Future<bool> launchExternalUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);

      if (!await canLaunchUrl(url)) {
        return false;
      }

      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      return false;
    }
  }

  /// Opens the SkillResy privacy policy page
  static Future<bool> launchPrivacyPolicy() async {
    return await launchExternalUrl('https://skillresy.com/privacy-policy/');
  }

  /// Opens the SkillResy terms of use page
  static Future<bool> launchTermsOfUse() async {
    return await launchExternalUrl('https://skillresy.com/terms-of-use/');
  }

  /// Opens the SkillResy opt-out policy page
  static Future<bool> launchOptOutPolicy() async {
    return await launchExternalUrl('https://skillresy.com/opt-out-policy/');
  }

  /// Helper to properly encode query parameters for mailto URIs (important for Android 11+)
  static String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  /// Opens the default email client with support email and prefilled subject
  static Future<bool> launchSupportEmail({
    String subject = 'Suspended Account Support',
  }) async {
    try {
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: 'support@skillresy.com',
        query: _encodeQueryParameters(<String, String>{
          'subject': subject,
        }),
      );

      // We directly launch the URL (which works more reliably on Android 11+ without package visibility issues)
      return await launchUrl(emailLaunchUri);
    } catch (e) {
      return false;
    }
  }
}
