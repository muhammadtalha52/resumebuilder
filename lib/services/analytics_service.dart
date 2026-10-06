import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../utils/endpoint_headers.dart';

class AnalyticsService {
  static final _fb = FacebookAppEvents();
  static final _ga = FirebaseAnalytics.instance;

  /// Event 1: Registration
  static Future<void> logRegistration(String userType) async {
    // Meta: CompleteRegistration (standard event)
    try {
      debugPrint("📘 META PIXEL EVENT: fb_mobile_complete_registration | params: {fb_registration_method: $userType}");
      await _fb.logEvent(
        name: 'fb_mobile_complete_registration',
        parameters: {'fb_registration_method': userType},
      );
    } catch (e) {
      debugPrint('❌ Failed to log Meta registration event: $e');
    }
    // GA4: sign_up (recommended event)
    try {
      debugPrint("🟢 GA4 EVENT: sign_up | params: {type: $userType}");
      await _ga.logEvent(name: 'sign_up', parameters: {'type': userType});
    } catch (e) {
      debugPrint('❌ Failed to log GA registration event: $e');
    }
  }

  /// Event 2: Credits Spent
  static Future<void> logCreditsSpent(int amount) async {
    try {
      debugPrint("📘 META PIXEL EVENT: credits_spent | params: {amount_spent: $amount}");
      await _fb.logEvent(
        name: 'credits_spent',
        parameters: {'amount_spent': amount},
      );
    } catch (e) {
      debugPrint('❌ Failed to log Meta credits spent event: $e');
    }
    
    try {
      debugPrint("🟢 GA4 EVENT: credits_spent | params: {amount_spent: $amount}");
      await _ga.logEvent(
        name: 'credits_spent',
        parameters: {'amount_spent': amount},
      );
    } catch (e) {
      debugPrint('❌ Failed to log GA credits spent event: $e');
    }
  }

  /// Event 3: Credit Limit Hit
  static Future<void> logCreditLimitHit() async {
    try {
      debugPrint("📘 META PIXEL EVENT: credit_limit_hit");
      await _fb.logEvent(name: 'credit_limit_hit');
    } catch (e) {
      debugPrint('❌ Failed to log Meta credit limit hit event: $e');
    }
    
    try {
      debugPrint("🟢 GA4 EVENT: credit_limit_hit");
      await _ga.logEvent(name: 'credit_limit_hit');
    } catch (e) {
      debugPrint('❌ Failed to log GA credit limit hit event: $e');
    }
  }

  /// Event 4: Purchase
  static Future<void> logPurchase({
    required String transactionId,
    required double value,
    String currency = 'USD',
  }) async {
    // Meta: Purchase (standard event)
    try {
      debugPrint("📘 META PIXEL EVENT: Purchase | params: {amount: $value, currency: $currency}");
      await _fb.logPurchase(amount: value, currency: currency);
    } catch (e) {
      debugPrint('❌ Failed to log Meta purchase event: $e');
    }
    // GA4: purchase (recommended event)
    try {
      debugPrint("🟢 GA4 EVENT: purchase | params: {transaction_id: $transactionId, value: $value, currency: $currency}");
      await _ga.logEvent(name: 'purchase', parameters: {
        'transaction_id': transactionId,
        'value': value,
        'currency': currency,
      });
    } catch (e) {
      debugPrint('❌ Failed to log GA purchase event: $e');
    }
  }

  /// Event 5: Paywall Shown
  static Future<void> logPaywallShown({required String trigger}) async {
    try {
      debugPrint("📘 META PIXEL EVENT: paywall_shown | params: {trigger: $trigger}");
      await _fb.logEvent(
        name: 'paywall_shown',
        parameters: {'trigger': trigger},
      );
    } catch (e) {
      debugPrint('❌ Failed to log Meta paywall shown event: $e');
    }
    
    try {
      debugPrint("🟢 GA4 EVENT: paywall_shown | params: {trigger: $trigger}");
      await _ga.logEvent(
        name: 'paywall_shown',
        parameters: {'trigger': trigger},
      );
    } catch (e) {
      debugPrint('❌ Failed to log GA paywall shown event: $e');
    }
  }

  /// Backend Event Tracking API (Fire and forget)
  static Future<void> logBackendEvent(String eventName, {Map<String, dynamic> properties = const {}}) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      debugPrint("🚀 BACKEND EVENT: $eventName | params: $properties | platform: $platform");
      
      APIClient().dio.post(
        ApiEndpoints.trackEvent,
        data: {
          "event": eventName,
          "properties": properties,
          "platform": platform,
        },
        options: Options(
          headers: {
            WAInterceptorHeaders.requiresToken: true,
          }
        )
      ).catchError((e) {
        debugPrint('❌ Failed to log Backend event (fire-and-forget): $eventName - Error: $e');
        return Response(requestOptions: RequestOptions(path: ''));
      });
    } catch (e) {
      debugPrint('❌ Failed to construct Backend event: $eventName - Error: $e');
    }
  }
}
