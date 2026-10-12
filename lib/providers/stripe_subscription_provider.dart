import 'dart:developer';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/backend_plan_model.dart';
import '../models/stripe_subscription_model.dart';
import '../services/stripe_subscription_service.dart';
import 'api_provider.dart';

class StripeSubscriptionState extends Equatable {
  final bool isLoading;
  final bool isCheckingOut;
  final bool isVerifying;
  final bool isUpdating;
  final bool isCanceling;
  final int? checkingOutPlanId;
  final List<BackendPlanModel> plans;
  final StripeSubscription? subscription;
  final SubscriptionCredits credits;
  final List<SubscriptionPayment> payments;
  final String? error;
  final String? successMessage;
  final String? pendingSessionId;

  const StripeSubscriptionState({
    this.isLoading = false,
    this.isCheckingOut = false,
    this.isVerifying = false,
    this.isUpdating = false,
    this.isCanceling = false,
    this.checkingOutPlanId,
    this.plans = const [],
    this.subscription,
    this.credits = const SubscriptionCredits(),
    this.payments = const [],
    this.error,
    this.successMessage,
    this.pendingSessionId,
  });

  bool get hasActiveSubscription =>
      subscription != null && subscription!.isActiveOrTrial;

  StripeSubscriptionState copyWith({
    bool? isLoading,
    bool? isCheckingOut,
    bool? isVerifying,
    bool? isUpdating,
    bool? isCanceling,
    int? checkingOutPlanId,
    bool clearCheckingOutPlanId = false,
    List<BackendPlanModel>? plans,
    StripeSubscription? subscription,
    bool clearSubscription = false,
    SubscriptionCredits? credits,
    List<SubscriptionPayment>? payments,
    String? error,
    bool clearError = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    String? pendingSessionId,
    bool clearPendingSessionId = false,
  }) {
    return StripeSubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      isVerifying: isVerifying ?? this.isVerifying,
      isUpdating: isUpdating ?? this.isUpdating,
      isCanceling: isCanceling ?? this.isCanceling,
      checkingOutPlanId: clearCheckingOutPlanId
          ? null
          : (checkingOutPlanId ?? this.checkingOutPlanId),
      plans: plans ?? this.plans,
      subscription: clearSubscription ? null : (subscription ?? this.subscription),
      credits: credits ?? this.credits,
      payments: payments ?? this.payments,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      pendingSessionId: clearPendingSessionId
          ? null
          : (pendingSessionId ?? this.pendingSessionId),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isCheckingOut,
        isVerifying,
        isUpdating,
        isCanceling,
        checkingOutPlanId,
        plans,
        subscription,
        credits,
        payments,
        error,
        successMessage,
        pendingSessionId,
      ];
}

class StripeSubscriptionNotifier
    extends StateNotifier<StripeSubscriptionState> {
  final StripeSubscriptionService _service;

  StripeSubscriptionNotifier(this._service)
      : super(const StripeSubscriptionState());

  /// Load plans and subscription data together
  Future<void> loadData({int? role}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final plansFuture = _service.fetchSubscriptionPlans(role: role);
      final subFuture = _service.getSubscriptionState();

      final results = await Future.wait([
        plansFuture,
        subFuture,
      ]);

      final plans = results[0] as List<BackendPlanModel>;
      final subState = results[1] as SubscriptionStateResponse;

      state = state.copyWith(
        isLoading: false,
        plans: plans,
        subscription: subState.subscription,
        clearSubscription: subState.subscription == null,
        credits: subState.credits,
        payments: subState.payments,
      );
    } catch (e) {
      log('[StripeProvider] Error loading data: $e');
      // If subscription state failed (e.g., new user with no subscription yet)
      // still try to load plans
      try {
        final plans = await _service.fetchSubscriptionPlans(role: role);
        state = state.copyWith(
          isLoading: false,
          plans: plans,
        );
      } catch (_) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load subscription plans. Please try again.',
        );
      }
    }
  }

  /// Refresh current subscription state and credits
  Future<void> refreshSubscription() async {
    try {
      final subState = await _service.getSubscriptionState();
      state = state.copyWith(
        subscription: subState.subscription,
        clearSubscription: subState.subscription == null,
        credits: subState.credits,
        payments: subState.payments,
      );
    } catch (e) {
      log('[StripeProvider] Error refreshing subscription: $e');
    }
  }

  /// Start checkout flow:
  /// 1. POST /plan/subscription/checkout/
  /// 2. Open checkoutUrl in system browser sheet (inAppBrowserView)
  /// 3. Upon sheet close, call POST /plan/subscription/verify/
  Future<void> startCheckout(
    BuildContext context,
    BackendPlanModel plan,
  ) async {
    state = state.copyWith(
      isCheckingOut: true,
      checkingOutPlanId: plan.id,
      clearError: true,
      clearSuccessMessage: true,
    );

    try {
      final checkoutData =
          await _service.createCheckoutSession(planId: plan.id);
      final checkoutUrl = checkoutData.checkoutUrl;
      final sessionId = checkoutData.sessionId;

      state = state.copyWith(
        isCheckingOut: false,
        clearCheckingOutPlanId: true,
        pendingSessionId: sessionId,
      );

      final uri = Uri.parse(checkoutUrl);

      // Open in system browser sheet (Safari View Controller on iOS, Custom Tabs on Android)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );

      if (!launched) {
        state = state.copyWith(
          isCheckingOut: false,
          clearCheckingOutPlanId: true,
          error: 'Could not launch checkout page. Please try again.',
        );
        return;
      }

      // User closed the browser sheet -> verify payment
      await verifySession(sessionId);
    } on StripeSubscriptionException catch (e) {
      state = state.copyWith(
        isCheckingOut: false,
        clearCheckingOutPlanId: true,
        error: e.message,
      );
    } catch (e) {
      log('[StripeProvider] Unexpected error in startCheckout: $e');
      state = state.copyWith(
        isCheckingOut: false,
        clearCheckingOutPlanId: true,
        error: 'Unable to start checkout. Please try again.',
      );
    }
  }

  /// Verify session with backend
  Future<void> verifySession(String sessionId) async {
    state = state.copyWith(
      isVerifying: true,
      clearError: true,
      clearSuccessMessage: true,
    );

    try {
      final result =
          await _service.verifyCheckoutSession(sessionId: sessionId);

      state = state.copyWith(
        isVerifying: false,
        subscription: result.subscription,
        clearSubscription: result.subscription == null,
        credits: result.credits,
        payments: result.payments,
        successMessage: 'Subscription activated successfully!',
        clearPendingSessionId: true,
      );
    } on CheckoutNotFinishedException {
      // User closed the sheet without paying: show nothing new, let them try again
      log('[StripeProvider] Checkout was closed without finishing payment');
      state = state.copyWith(
        isVerifying: false,
        clearPendingSessionId: true,
      );
    } on StripeSubscriptionException catch (e) {
      state = state.copyWith(
        isVerifying: false,
        error: e.message,
        clearPendingSessionId: true,
      );
    } catch (e) {
      log('[StripeProvider] Error verifying session: $e');
      state = state.copyWith(
        isVerifying: false,
        clearPendingSessionId: true,
      );
    }
  }

  /// Upgrade or Downgrade subscription (PUT /plan/subscription/update/)
  Future<void> updateSubscriptionPlan(
    BuildContext context,
    BackendPlanModel targetPlan,
  ) async {
    state = state.copyWith(
      isUpdating: true,
      clearError: true,
      clearSuccessMessage: true,
    );

    try {
      final result =
          await _service.updateSubscription(planId: targetPlan.id);

      final isEffectiveNow = result.effective == 'now';
      final message = isEffectiveNow
          ? 'Upgraded to ${targetPlan.name}! Difference charged today and your new plan credits have arrived.'
          : 'Plan changed! Downgrade to ${targetPlan.name} will start at your next renewal.';

      state = state.copyWith(
        isUpdating: false,
        subscription: result.subscription,
        clearSubscription: result.subscription == null,
        credits: result.credits,
        payments: result.payments,
        successMessage: message,
      );
    } on StripeSubscriptionException catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.message,
      );
    } catch (e) {
      log('[StripeProvider] Error updating subscription: $e');
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update subscription. Please check your card.',
      );
    }
  }

  /// Cancel or Undo Cancel subscription (POST /plan/subscription/cancel/)
  Future<void> cancelOrResumeSubscription({bool undo = false}) async {
    state = state.copyWith(
      isCanceling: true,
      clearError: true,
      clearSuccessMessage: true,
    );

    try {
      final result = await _service.cancelSubscription(undo: undo);

      final message = undo
          ? 'Cancellation undone! Your plan will renew as scheduled.'
          : (state.subscription?.inTrial == true
              ? 'Trial cancelled. Trial ended immediately.'
              : 'Subscription cancelled. You will retain access until the end of the paid period.');

      state = state.copyWith(
        isCanceling: false,
        subscription: result.subscription,
        clearSubscription: result.subscription == null,
        credits: result.credits,
        payments: result.payments,
        successMessage: message,
      );
    } on StripeSubscriptionException catch (e) {
      state = state.copyWith(
        isCanceling: false,
        error: e.message,
      );
    } catch (e) {
      log('[StripeProvider] Error cancelling subscription: $e');
      state = state.copyWith(
        isCanceling: false,
        error: 'Could not update cancellation status. Please try again.',
      );
    }
  }

  /// Open Stripe Invoice in browser
  Future<void> openInvoice(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      log('[StripeProvider] Could not open invoice: $e');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSuccessMessage() {
    state = state.copyWith(clearSuccessMessage: true);
  }
}

final stripeSubscriptionServiceProvider =
    Provider<StripeSubscriptionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StripeSubscriptionService(client: apiClient);
});

final stripeSubscriptionProvider = StateNotifierProvider<
    StripeSubscriptionNotifier, StripeSubscriptionState>((ref) {
  final service = ref.watch(stripeSubscriptionServiceProvider);
  return StripeSubscriptionNotifier(service);
});
