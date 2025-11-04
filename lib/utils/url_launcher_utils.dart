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
}
