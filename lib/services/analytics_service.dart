import 'package:get_storage/get_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../utils/endpoint_headers.dart';

class AnalyticsService {
  /// Enable or disable advertiser tracking on iOS (ATT)
  static Future<void> setAdvertiserTracking(bool enabled) async {
    try {
      await _fb.setAdvertiserTracking(enabled: enabled);
      debugPrint("📘 [META iOS] Advertiser tracking set to: $enabled");
    } catch (e) {
      debugPrint("❌ Failed to set advertiser tracking: $e");
    }
  }

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
      await _fb.flush();
      debugPrint("✅ [META SDK FLUSHED] fb_mobile_complete_registration sent!");
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
      await _fb.flush();
      debugPrint("✅ [META SDK FLUSHED] credits_spent sent!");
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
      await _fb.flush();
      debugPrint("✅ [META SDK FLUSHED] credit_limit_hit sent!");
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

  /// Event 4: Purchase (Logged to Meta Pixel/SDK, GA4/gtag, and Backend)
  static Future<void> logPurchase({
    required String transactionId,
    required double value,
    String currency = 'USD',
    String? planName,
    String? productId,
  }) async {
    // Strictly deduplicate by transaction/session id so retries don't log duplicate purchases
    final box = GetStorage();
    final dedupKey = 'purchase_tracked_$transactionId';
    if (transactionId.isNotEmpty && transactionId != 'unknown' && box.read(dedupKey) == true) {
      debugPrint("ℹ️ [DEDUP] Purchase already tracked for transaction: $transactionId — skipping duplicate");
      return;
    }
    if (transactionId.isNotEmpty && transactionId != 'unknown') {
      await box.write(dedupKey, true);
    }

    // 1. Meta Pixel / App Events: Standard Purchase event
    try {
      final metaParams = <String, dynamic>{
        'transaction_id': transactionId,
      };
      if (planName != null) metaParams['content_name'] = planName;
      if (productId != null) metaParams['content_id'] = productId;
      debugPrint("📘 META PIXEL EVENT: Purchase | amount: $value, currency: $currency, params: $metaParams");
      await _fb.logPurchase(
        amount: value,
        currency: currency,
        parameters: metaParams,
      );
      await _fb.flush();
      debugPrint("✅ [META SDK FLUSHED] Purchase sent!");
    } catch (e) {
      debugPrint('❌ Failed to log Meta purchase event: $e');
    }

    // 2. GA4 / Firebase Analytics (Google gtag Purchase Event)
    try {
      debugPrint("🟢 GA4/GTAG EVENT: purchase | params: {transaction_id: $transactionId, value: $value, currency: $currency, item: $planName}");
      await _ga.logPurchase(
        currency: currency,
        value: value,
        transactionId: transactionId,
        items: [
          AnalyticsEventItem(
            itemName: planName ?? 'Subscription Plan',
            itemId: productId ?? transactionId,
            price: value,
            quantity: 1,
          ),
        ],
      );
    } catch (e) {
      debugPrint('❌ Failed to log GA purchase event: $e');
    }

    // 3. Backend Event
    final backendProps = <String, dynamic>{
      'transaction_id': transactionId,
      'value': value,
      'currency': currency,
    };
    if (planName != null) backendProps['plan_name'] = planName;
    if (productId != null) backendProps['product_id'] = productId;
    logBackendEvent('purchase', properties: backendProps);
  }
  /// Event 5: Paywall Shown
  static Future<void> logPaywallShown({required String trigger}) async {
    try {
      debugPrint("🚀 [META SDK TRIGGERED] Event: paywall_shown | trigger: $trigger");
      await _fb.logEvent(
        name: 'paywall_shown',
        parameters: {'trigger': trigger},
      );
      await _fb.flush();
      debugPrint("✅ [META SDK FLUSHED] paywall_shown successfully sent to Meta servers!");
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

  /// Tour Event: tour_started
  static Future<void> logTourStarted({String audience = 'b2c'}) async {
    final params = {'audience': audience};
    try {
      debugPrint("🚀 [TOUR] tour_started: $params");
      await _fb.logEvent(name: 'tour_started', parameters: params);
      await _fb.flush();
      await _ga.logEvent(name: 'tour_started', parameters: params);
    } catch (e) {
      debugPrint("❌ Error logging tour_started: $e");
    }
    logBackendEvent('tour_started', properties: params);
  }

  /// Tour Event: tour_completed
  static Future<void> logTourCompleted({int stepsCompleted = 4}) async {
    final params = {'steps_completed': stepsCompleted};
    try {
      debugPrint("🚀 [TOUR] tour_completed: $params");
      await _fb.logEvent(name: 'tour_completed', parameters: params);
      await _fb.flush();
      await _ga.logEvent(name: 'tour_completed', parameters: params);
    } catch (e) {
      debugPrint("❌ Error logging tour_completed: $e");
    }
    logBackendEvent('tour_completed', properties: params);
  }

  /// Tour Event: tour_skipped
  static Future<void> logTourSkipped({required int stepNumber}) async {
    final params = {'step_number': stepNumber};
    try {
      debugPrint("🚀 [TOUR] tour_skipped: $params");
      await _fb.logEvent(name: 'tour_skipped', parameters: params);
      await _fb.flush();
      await _ga.logEvent(name: 'tour_skipped', parameters: params);
    } catch (e) {
      debugPrint("❌ Error logging tour_skipped: $e");
    }
    logBackendEvent('tour_skipped', properties: params);
  }

  /// Paywall Event: paywall_dismissed
  static Future<void> logPaywallDismissed({required String reason}) async {
    final params = {'reason': reason};
    try {
      debugPrint("🚀 [PAYWALL] paywall_dismissed: $params");
      await _fb.logEvent(name: 'paywall_dismissed', parameters: params);
      await _fb.flush();
      await _ga.logEvent(name: 'paywall_dismissed', parameters: params);
    } catch (e) {
      debugPrint("❌ Error logging paywall_dismissed: $e");
    }
    logBackendEvent('paywall_dismissed', properties: params);
  }

  /// Paywall Event: trial_start_clicked
  static Future<void> logTrialStartClicked({
    required int planId,
    required String planName,
    required dynamic price,
  }) async {
    final params = {
      'plan_id': planId,
      'plan_name': planName,
      'price': price.toString(),
    };
    try {
      debugPrint("🚀 [PAYWALL] trial_start_clicked: $params");
      await _fb.logEvent(name: 'trial_start_clicked', parameters: params);
      await _fb.flush();
      await _ga.logEvent(name: 'trial_start_clicked', parameters: params);
    } catch (e) {
      debugPrint("❌ Error logging trial_start_clicked: $e");
    }
    logBackendEvent('trial_start_clicked', properties: params);
  }

  /// Thank-You Event: trial_started (Strictly deduplicated)
  static Future<void> logTrialStartedStrictOnce({
    required String planName,
    required double value,
    String currency = 'USD',
    required String sessionId,
  }) async {
    final box = GetStorage();
    final dedupKey = 'trial_started_tracked_$sessionId';
    if (box.read(dedupKey) == true) {
      debugPrint("ℹ️ [DEDUP] trial_started already tracked for session: $sessionId — skipping");
      return;
    }
    await box.write(dedupKey, true);

    final params = {
      'plan_name': planName,
      'value': value,
      'currency': currency,
      'session_id': sessionId,
    };
    try {
      debugPrint("🚀 [TRIAL] trial_started: $params");
      await _fb.logEvent(name: 'trial_started', parameters: params);
      await _fb.flush();
      await _ga.logEvent(name: 'trial_started', parameters: params);
    } catch (e) {
      debugPrint("❌ Error logging trial_started: $e");
    }
    logBackendEvent('trial_started', properties: params);
  }
}
