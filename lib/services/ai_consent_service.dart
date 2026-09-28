import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../utils/endpoint_headers.dart';

/// Service for managing user consent for third-party AI data sharing (Apple App Store Guideline 5.1.1 / 5.1.2 compliance).
class AIConsentService {
  AIConsentService._();

  static const String _noticeVersion = "2026-09";

  static const String _consentKey = 'hasAcceptedAIDataConsent';
  static const String _resumeConsentKey = 'hasAcceptedResumeAIDataConsent';
  static const String _consentVersionKey = 'aiConsentVersion';

  /// Current local consent version fallback.
  static const int currentConsentVersion = 1;

  /// Returns true if the user has accepted third-party AI data consent.
  static Future<bool> hasConsent({bool isResume = false}) async {
    debugPrint("=== AI CONSENT CHECK (isResume: $isResume) ===");
    
    // NOTE: Commented out iOS-only check so you can test this on Android!
    // if (!Platform.isIOS) {
    //   debugPrint("Platform is not iOS. Bypassing consent.");
    //   return true;
    // }

    try {
      final dio = APIClient().dio;
      final providers = isResume ? ["OpenAI"] : ["AssemblyAI", "OpenAI"];
      final queryParam = providers.join(',');
      
      final url = '${ApiEndpoints.aiConsent}?providers=$queryParam';
      debugPrint("Hitting GET $url");
      
      final response = await dio.get(
        url,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );
      
      debugPrint("API Response Status: ${response.statusCode}");
      debugPrint("API Response Data: ${response.data}");
      
      if (response.statusCode == 200) {
        // Backend returns: { "status": "success", "data": { "has_consented": ... } }
        final responseData = response.data;
        final data = responseData['data'] ?? responseData; // Fallback in case of flat structure
        
        final bool hasConsented = data['has_consented'] ?? false;
        
        if (hasConsented) {
          debugPrint("Result: Consent valid and up to date for $providers!");
          return true;
        } else {
          final missing = data['missing_providers'];
          debugPrint("Result: User has missing consents: $missing");
        }
        return false; 
      }
    } catch (e) {
      debugPrint("API Call Failed. Falling back to SharedPreferences. Error: $e");
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = isResume ? _resumeConsentKey : _consentKey;
      final hasAccepted = prefs.getBool(key) ?? false;
      final savedVersion = prefs.getInt(_consentVersionKey) ?? 0;
      
      debugPrint("Local Fallback -> hasAccepted: $hasAccepted, savedVersion: $savedVersion");
      return hasAccepted && (savedVersion >= currentConsentVersion);
    } catch (_) {
      return false;
    }
  }

  /// Persists user consent to backend and locally.
  static Future<void> acceptConsent({bool isResume = false, bool accepted = true}) async {
    debugPrint("=== POSTING AI CONSENT (Accepted: $accepted, isResume: $isResume) ===");
    try {
      final dio = APIClient().dio;
      final providers = isResume ? ["OpenAI"] : ["AssemblyAI", "OpenAI"];
      
      final payload = {
        "accepted": accepted,
        "providers": providers,
        "notice_version": _noticeVersion,
        "platform": Platform.operatingSystem,
      };
      debugPrint("Payload: $payload");
      
      final response = await dio.post(
        ApiEndpoints.aiConsent,
        data: payload,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );
      debugPrint("POST Success. Status: ${response.statusCode}");
    } catch (e) {
      debugPrint("POST Failed. Error: $e");
    }

    // Local fallback persistence
    if (accepted) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = isResume ? _resumeConsentKey : _consentKey;
        await prefs.setBool(key, true);
        await prefs.setInt(_consentVersionKey, currentConsentVersion);
        debugPrint("Saved to local SharedPreferences as fallback.");
      } catch (_) {}
    }
  }

  /// Resets local consent state (useful for testing or user account wipe).
  static Future<void> resetConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_consentKey);
      await prefs.remove(_resumeConsentKey);
      await prefs.remove(_consentVersionKey);
      debugPrint("Local consent cache cleared.");
    } catch (_) {}
  }
}
