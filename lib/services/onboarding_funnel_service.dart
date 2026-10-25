import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'app_logic.dart';

/// Service managing Guided Tour, Paywall Cooldown, and Session Capping.
/// Matches the Web Portal monetization and onboarding contract.
class OnboardingFunnelService {
  static final OnboardingFunnelService instance =
      OnboardingFunnelService._internal();

  OnboardingFunnelService._internal();

  final GetStorage _box = GetStorage();
  final APIClient _apiClient = APIClient();

  // Storage Keys
  static const String keyTourCompleted = 'onboarding_tour_completed_permanent';
  static const String keyPaywallDismissedAt = 'paywall_dismissed_at_permanent';
  static const int cooldown72HoursMs = 72 * 60 * 60 * 1000; // 3 Days in ms

  // In-Memory Session Flag (Resets on every app process launch)
  static bool paywallShownInCurrentSession = false;

  // ---------------------------------------------------------
  // Guided Tour State & Sync
  // ---------------------------------------------------------

  /// Check if the tour was completed locally in SharedPreferences or GetStorage
  Future<bool> isTourCompletedLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final email = AppLogic().user?.email;
      if (email != null && email.isNotEmpty) {
        if (prefs.getBool('${keyTourCompleted}_$email') == true) {
          return true;
        }
      }

      final userId = AppLogic().user?.id;
      if (userId != null) {
        if (prefs.getBool('${keyTourCompleted}_$userId') == true) {
          return true;
        }
      }

      if (prefs.getBool(keyTourCompleted) == true) {
        return true;
      }
    } catch (e) {
      debugPrint('[TourService] Error reading SharedPreferences: $e');
    }

    return _box.read<bool>(keyTourCompleted) ?? false;
  }

  /// Mark tour completed permanently in SharedPreferences & GetStorage, and sync with backend
  Future<void> markTourCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyTourCompleted, true);

      final email = AppLogic().user?.email;
      if (email != null && email.isNotEmpty) {
        await prefs.setBool('${keyTourCompleted}_$email', true);
      }

      final userId = AppLogic().user?.id;
      if (userId != null) {
        await prefs.setBool('${keyTourCompleted}_$userId', true);
      }
    } catch (e) {
      debugPrint('[TourService] Error writing SharedPreferences: $e');
    }

    await _box.write(keyTourCompleted, true);
    debugPrint('[TourService] Tour marked completed permanently.');

    // Fire and forget backend sync (no UI delay before paywall opens)
    _apiClient.dio.post(
      '/api/auth/onboarding/',
      data: {'tour_completed': true},
      options: Options(
        headers: {'Requires-Token': true},
        validateStatus: (status) => true,
      ),
    ).then((response) {
      debugPrint('[TourService] Synced tour status with backend: ${response.statusCode}');
    }).catchError((e) {
      debugPrint('[TourService] Backend onboarding sync deferred: $e');
    });
  }

  /// Reset tour locally (for "Take the tour again" option in profile)
  Future<void> resetTour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyTourCompleted, false);

      final email = AppLogic().user?.email;
      if (email != null && email.isNotEmpty) {
        await prefs.setBool('${keyTourCompleted}_$email', false);
      }

      final userId = AppLogic().user?.id;
      if (userId != null) {
        await prefs.setBool('${keyTourCompleted}_$userId', false);
      }
    } catch (e) {
      debugPrint('[TourService] Error resetting SharedPreferences: $e');
    }

    await _box.write(keyTourCompleted, false);
    debugPrint('[TourService] Tour reset locally for replay.');
  }

  /// Prepares a new signup for the onboarding flow.
  /// Clears tour status and paywall cooldown in SharedPreferences and GetStorage
  /// so the newly registered user experiences the Guided Tour upon entering /home.
  Future<void> prepareNewSignupForTour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyTourCompleted, false);
      final email = AppLogic().user?.email;
      if (email != null && email.isNotEmpty) {
        await prefs.setBool('${keyTourCompleted}_$email', false);
      }
      final userId = AppLogic().user?.id;
      if (userId != null) {
        await prefs.setBool('${keyTourCompleted}_$userId', false);
      }
      await prefs.remove(keyPaywallDismissedAt);
    } catch (e) {
      debugPrint('[TourService] Error clearing prefs on new signup: $e');
    }

    await _box.write(keyTourCompleted, false);
    await _box.remove(keyPaywallDismissedAt);
    paywallShownInCurrentSession = false;
    debugPrint('[TourService] New signup prepared: tour reset and paywall cooldown cleared.');
  }

  /// Sync onboarding status on app launch or login
  Future<bool> fetchOnboardingStatusFromBackend() async {
    // 1. If already completed locally in permanent storage, return true immediately!
    final locallyDone = await isTourCompletedLocally();
    if (locallyDone) {
      debugPrint('[TourService] Tour already completed permanently. Suppressing tour.');
      return true;
    }

    // 2. Otherwise check backend sync
    try {
      final response = await _apiClient.dio.get(
        '/api/auth/onboarding/',
        options: Options(
          headers: {'Requires-Token': true},
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        bool? backendCompleted;
        if (data is Map) {
          if (data.containsKey('data') && data['data'] is Map) {
            final inner = data['data'];
            if (inner.containsKey('tour_completed')) {
              backendCompleted = inner['tour_completed'] == true;
            }
          } else if (data.containsKey('tour_completed')) {
            backendCompleted = data['tour_completed'] == true;
          }
        }
        if (backendCompleted == true) {
          await markTourCompleted();
          return true;
        }
      }
    } catch (e) {
      log('[TourService] Could not fetch backend onboarding status: $e');
    }
    return false;
  }

  // ---------------------------------------------------------
  // Paywall Eligibility & 72-Hour Cooldown
  // ---------------------------------------------------------

  /// Determines whether the paywall modal is eligible to pop up.
  ///
  /// Rules:
  /// 1. Never show if user has an active subscription or running trial.
  /// 2. Never show more than once in the same app session.
  /// 3. If dismissed earlier, enforce a strict 72-hour (3 days) cooldown.
  bool canShowPaywallModal({required bool hasActiveSubscription}) {
    // Golden Rule: Active paid/trial users never see paywalls
    if (hasActiveSubscription) {
      debugPrint('[Paywall] Blocked: User already has active plan or trial.');
      return false;
    }

    // Session Cap: At most once per app session
    if (paywallShownInCurrentSession) {
      debugPrint('[Paywall] Blocked: Already shown in this session.');
      return false;
    }

    // 72-Hour Cooldown Check from memory / GetStorage
    final dismissedAt = _box.read<int>(keyPaywallDismissedAt);
    if (dismissedAt != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - dismissedAt;
      if (elapsed < cooldown72HoursMs) {
        final remainingHours =
            ((cooldown72HoursMs - elapsed) / (1000 * 60 * 60)).toStringAsFixed(1);
        debugPrint(
          '[Paywall] Blocked by 72h Cooldown. $remainingHours hours remaining.',
        );
        return false;
      }
    }

    return true;
  }

  /// Async check for paywall cooldown reading from SharedPreferences
  Future<bool> canShowPaywallModalAsync({required bool hasActiveSubscription}) async {
    if (hasActiveSubscription) return false;
    if (paywallShownInCurrentSession) return false;

    int? dismissedAt = _box.read<int>(keyPaywallDismissedAt);
    if (dismissedAt == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        dismissedAt = prefs.getInt(keyPaywallDismissedAt);
      } catch (_) {}
    }

    if (dismissedAt != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - dismissedAt;
      if (elapsed < cooldown72HoursMs) {
        final remainingHours =
            ((cooldown72HoursMs - elapsed) / (1000 * 60 * 60)).toStringAsFixed(1);
        debugPrint(
          '[Paywall] Blocked by 72h Cooldown. $remainingHours hours remaining.',
        );
        return false;
      }
    }

    return true;
  }

  /// Mark paywall as shown in current session
  void markPaywallShownInSession() {
    paywallShownInCurrentSession = true;
  }

  /// Record user dismissal ("Not now" or 'X') and start 72-hour cooldown
  Future<void> recordPaywallDismissal() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(keyPaywallDismissedAt, nowMs);
    } catch (_) {}
    await _box.write(keyPaywallDismissedAt, nowMs);
    debugPrint('[Paywall] Dismissed at $nowMs — 72-hour cooldown activated.');
  }

  /// Clear cooldown (e.g. for testing)
  Future<void> clearPaywallCooldown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyPaywallDismissedAt);
    } catch (_) {}
    await _box.remove(keyPaywallDismissedAt);
    paywallShownInCurrentSession = false;
  }
}
