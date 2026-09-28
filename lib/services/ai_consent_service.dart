import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user consent for third-party AI data sharing (Apple App Store Guideline 5.1.1 / 5.1.2 compliance).
class AIConsentService {
  AIConsentService._();

  static const String _consentKey = 'hasAcceptedAIDataConsent';
  static const String _consentVersionKey = 'aiConsentVersion';

  /// Current consent version. Bump this value in future releases whenever AI data sharing terms change to force re-consent.
  static const int currentConsentVersion = 1;

  /// Returns true if the user has accepted third-party AI data consent (or if platform is not iOS/iPadOS).
  static Future<bool> hasConsent() async {
    // Only required on iOS / iPadOS
    if (!Platform.isIOS) {
      return true;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAccepted = prefs.getBool(_consentKey) ?? false;
      final savedVersion = prefs.getInt(_consentVersionKey) ?? 0;

      return hasAccepted && (savedVersion >= currentConsentVersion);
    } catch (_) {
      return false;
    }
  }

  /// Persists user consent along with the current consent version.
  static Future<void> acceptConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_consentKey, true);
      await prefs.setInt(_consentVersionKey, currentConsentVersion);
    } catch (_) {}
  }

  /// Resets consent state (useful for testing or user account wipe).
  static Future<void> resetConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_consentKey);
      await prefs.remove(_consentVersionKey);
    } catch (_) {}
  }
}
