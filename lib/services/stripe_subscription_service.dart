import 'dart:developer';
import 'package:dio/dio.dart';
import '../models/backend_plan_model.dart';
import '../models/stripe_subscription_model.dart';
import '../utils/endpoint_headers.dart';
import 'api_client.dart';

/// Exception thrown when a user leaves the checkout sheet without completing payment
class CheckoutNotFinishedException implements Exception {
  final String message;
  CheckoutNotFinishedException([this.message = 'That checkout is not finished']);

  @override
  String toString() => message;
}

class StripeSubscriptionException implements Exception {
  final String message;
  final int? statusCode;
  StripeSubscriptionException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class StripeSubscriptionService {
  final APIClient apiClient;

  StripeSubscriptionService({APIClient? client})
      : apiClient = client ?? APIClient();

  /// 1. List subscription plans from GET /api/plan/plans/one-time/
  /// Keeps only plans with is_subscription: true
  Future<List<BackendPlanModel>> fetchSubscriptionPlans({int? role}) async {
    try {
      log('[StripeService] Fetching subscription plans from ${ApiEndpoints.oneTimePlans}...');

      final response = await apiClient.dio.get(
        ApiEndpoints.oneTimePlans,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 && response.data != null) {
        print('\n======================================================');
        print('🔥 [BACKEND PLANS RAW RESPONSE /plan/plans/one-time/]:');
        print('${response.data}');
        print('======================================================\n');

        final plansResponse = PlansListResponse.fromJson(response.data);

        for (final p in plansResponse.data) {
          print(
            '📦 [PLAN ITEM] id: ${p.id} | name: "${p.name}" | product_id: "${p.productId}" | is_subscription: ${p.isSubscription} | price: ${p.price}',
          );
        }

        // Keep only active plans that are subscriptions
        var plans = plansResponse.data
            .where((p) => p.isSubscription && p.isActive)
            .toList();

        // Filter based on role if provided
        if (role == 1) {
          // Candidate plans (resumes, interviews, ask scout, or candidate plan names)
          plans = plans.where((p) {
            final isStudentPlan =
                (p.quizCount > 0 || p.documentUploadCount > 0) &&
                p.resumeCount == 0 &&
                p.interviewCount == 0;
            return !isStudentPlan;
          }).toList();
        } else if (role == 2) {
          // Student plans (quizzes, document uploads)
          plans = plans.where((p) {
            final isStudentPlan =
                p.quizCount > 0 ||
                p.documentUploadCount > 0 ||
                p.name.toLowerCase().contains('student') ||
                p.name.toLowerCase().contains('cram') ||
                p.name.toLowerCase().contains('nerd');
            return isStudentPlan;
          }).toList();
        }

        log('[StripeService] Found ${plans.length} subscription plans (role: $role)');
        return plans;
      } else {
        log('[StripeService] Failed to fetch plans: ${response.statusCode}');
        return [];
      }
    } on DioException catch (e) {
      log('[StripeService] DioException while fetching plans: ${e.message}');
      return [];
    } catch (e) {
      log('[StripeService] Error while fetching plans: $e');
      return [];
    }
  }

  /// 2. Get current subscription state from GET /api/plan/subscription/
  Future<SubscriptionStateResponse> getSubscriptionState() async {
    try {
      log('[StripeService] Fetching subscription state from ${ApiEndpoints.subscription}...');

      final response = await apiClient.dio.get(
        ApiEndpoints.subscription,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return SubscriptionStateResponse.fromJson(response.data);
      } else {
        final msg = response.data?['message'] ?? 'Failed to load subscription';
        throw StripeSubscriptionException(msg, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error occurred';
      log('[StripeService] DioException in getSubscriptionState: $msg');
      throw StripeSubscriptionException(msg, statusCode: e.response?.statusCode);
    } catch (e) {
      if (e is StripeSubscriptionException) rethrow;
      log('[StripeService] Unexpected error in getSubscriptionState: $e');
      throw StripeSubscriptionException('An unexpected error occurred');
    }
  }

  /// 3. Start Checkout: POST /api/plan/subscription/checkout/
  /// Body: { "plan_id": 12, "return_origin": "https://dev-app.skillresy.com" }
  Future<StripeCheckoutData> createCheckoutSession({required int planId}) async {
    final origin = ApiEndpoints.stripeReturnOrigin;
    try {
      log('[StripeService] Creating checkout session for planId: $planId, return_origin: $origin');

      final response = await apiClient.dio.post(
        ApiEndpoints.subscriptionCheckout,
        data: {
          'plan_id': planId,
          'return_origin': origin,
        },
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      final data = response.data;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data != null &&
          data['data'] != null) {
        return StripeCheckoutData.fromJson(data['data']);
      } else {
        final msg = data?['message'] ?? 'Could not create checkout session';
        throw StripeSubscriptionException(msg, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          'Could not start checkout';
      log('[StripeService] DioException in checkout: $msg');
      throw StripeSubscriptionException(msg, statusCode: e.response?.statusCode);
    } catch (e) {
      if (e is StripeSubscriptionException) rethrow;
      log('[StripeService] Unexpected error in checkout: $e');
      throw StripeSubscriptionException('Failed to initiate checkout');
    }
  }

  /// 5. Verify Checkout: POST /api/plan/subscription/verify/
  /// Body: { "session_id": "cs_..." }
  Future<SubscriptionStateResponse> verifyCheckoutSession({
    required String sessionId,
  }) async {
    try {
      log('[StripeService] Verifying checkout session: $sessionId');

      final response = await apiClient.dio.post(
        ApiEndpoints.subscriptionVerify,
        data: {'session_id': sessionId},
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        return SubscriptionStateResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final msg = data?['message'] ?? 'That checkout is not finished';
        throw CheckoutNotFinishedException(msg);
      } else {
        final msg = data?['message'] ?? 'Verification failed';
        throw StripeSubscriptionException(msg, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final msg = e.response?.data?['message'] ?? 'That checkout is not finished';
        throw CheckoutNotFinishedException(msg);
      }
      final msg = e.response?.data?['message'] ?? 'Verification request failed';
      throw StripeSubscriptionException(msg, statusCode: e.response?.statusCode);
    } catch (e) {
      if (e is CheckoutNotFinishedException || e is StripeSubscriptionException) {
        rethrow;
      }
      throw StripeSubscriptionException('Unexpected error verifying checkout');
    }
  }

  /// Update subscription (upgrade or downgrade): PUT /api/plan/subscription/update/
  /// Body: { "plan_id": 14 }
  Future<SubscriptionStateResponse> updateSubscription({
    required int planId,
  }) async {
    try {
      log('[StripeService] Updating subscription to planId: $planId');

      final response = await apiClient.dio.put(
        ApiEndpoints.subscriptionUpdate,
        data: {'plan_id': planId},
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        return SubscriptionStateResponse.fromJson(data);
      } else {
        final msg = data?['message'] ?? 'Failed to update subscription';
        throw StripeSubscriptionException(msg, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          'Failed to update subscription';
      throw StripeSubscriptionException(msg, statusCode: e.response?.statusCode);
    } catch (e) {
      if (e is StripeSubscriptionException) rethrow;
      throw StripeSubscriptionException('Unexpected error updating subscription');
    }
  }

  /// Cancel or Undo cancel: POST /api/plan/subscription/cancel/
  /// Body: {} or { "undo": true }
  Future<SubscriptionStateResponse> cancelSubscription({
    bool undo = false,
  }) async {
    try {
      log('[StripeService] Cancelling subscription (undo: $undo)');

      final response = await apiClient.dio.post(
        ApiEndpoints.subscriptionCancel,
        data: undo ? {'undo': true} : {},
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        return SubscriptionStateResponse.fromJson(data);
      } else {
        final msg = data?['message'] ?? 'Failed to process cancellation request';
        throw StripeSubscriptionException(msg, statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          'Cancellation request failed';
      throw StripeSubscriptionException(msg, statusCode: e.response?.statusCode);
    } catch (e) {
      if (e is StripeSubscriptionException) rethrow;
      throw StripeSubscriptionException('Unexpected error processing cancellation');
    }
  }

  /// Deduct Ask Scout question: POST /api/plan/allocation/use/
  /// { "resource_type": "ask_scout", "count": 1, "description": "Ask Scout question", "reference_id": sessionId }
  /// Returns true if credit deducted successfully, false if none left (400)
  Future<bool> deductAskScoutCredit({required String sessionId}) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.markCreditsUsed,
        data: {
          'resource_type': 'ask_scout',
          'count': 1,
          'description': 'Ask Scout question',
          'reference_id': sessionId,
        },
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      log('[StripeService] Ask Scout deduction failed: ${e.response?.statusCode} - ${e.message}');
      return false;
    } catch (e) {
      log('[StripeService] Unexpected error deducting Ask Scout credit: $e');
      return false;
    }
  }
}
