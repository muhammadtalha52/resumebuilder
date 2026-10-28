import 'package:dio/dio.dart';
import '../models/purchase_verification_model.dart';
import '../models/backend_plan_model.dart';
import '../models/purchase_product_model.dart';
import '../utils/endpoint_headers.dart';
import 'api_client.dart';

/// Service to handle subscription/IAP backend API calls
class SubscriptionService {
  final APIClient apiClient;

  SubscriptionService(this.apiClient);

  /// Verify a purchase with the backend
  /// Returns user data with updated credits if successful
  Future<PurchaseVerificationResponse> verifyPurchase(
    PurchaseVerificationRequest request,
  ) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.verifyPurchase,
        data: request.toJson(),
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PurchaseVerificationResponse.fromJson(response.data);
      } else {
        return PurchaseVerificationResponse(
          success: false,
          message: response.data['message'] ?? 'Purchase verification failed',
        );
      }
    } on DioException catch (e) {
      return PurchaseVerificationResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Network error occurred',
      );
    } catch (e) {
      return PurchaseVerificationResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get current credit status from backend

  /// Restore purchases from App Store/Play Store
  /// Send list of purchase receipts to backend for verification
  Future<PurchaseVerificationResponse> restorePurchases(
    List<PurchaseVerificationRequest> requests,
  ) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.restorePurchases,
        data: {'purchases': requests.map((r) => r.toJson()).toList()},
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PurchaseVerificationResponse.fromJson(response.data);
      } else {
        return PurchaseVerificationResponse(
          success: false,
          message: response.data['message'] ?? 'Restore failed',
        );
      }
    } on DioException catch (e) {
      return PurchaseVerificationResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Network error occurred',
      );
    } catch (e) {
      return PurchaseVerificationResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Process Google Pay payment
  Future<GooglePayPaymentResponse> processGooglePayPayment(
    GooglePayPaymentRequest request,
  ) async {
    try {
      print('[SubscriptionService] Sending Google Pay payment request:');
      print('  - Plan ID: ${request.planId}');
      print('  - Product ID: ${request.productId}');
      print('  - Package Name: ${request.packageName}');
      print('  - Payment Token: ${request.paymentToken}');
      print('  - Transaction ID: ${request.transactionId}');
      print('  - Notes: ${request.notes}');

      final response = await apiClient.dio.post(
        ApiEndpoints.googlePayPayment,
        data: request.toJson(),
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      print(
        '[SubscriptionService] Google Pay response status: ${response.statusCode}',
      );
      print('[SubscriptionService] Google Pay response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return GooglePayPaymentResponse.fromJson(response.data);
      } else {
        return GooglePayPaymentResponse(
          success: false,
          message: response.data['message'] ?? 'Payment processing failed',
        );
      }
    } on DioException catch (e) {
      print('[SubscriptionService] Google Pay DioException: ${e.message}');
      print('[SubscriptionService] Response data: ${e.response?.data}');
      return GooglePayPaymentResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Network error occurred',
      );
    } catch (e) {
      print('[SubscriptionService] Google Pay error: $e');
      return GooglePayPaymentResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Process Apple Pay payment
  Future<ApplePayPaymentResponse> processApplePayPayment(
    ApplePayPaymentRequest request,
  ) async {
    try {
      print('[SubscriptionService] Sending Apple Pay payment request:');
      print('  - Plan ID: ${request.planId}');
      print('  - Receipt Data: ${request.receiptData.substring(0, 50)}...');
      print('  - Transaction ID: ${request.transactionId}');
      print('  - Notes: ${request.notes}');

      final response = await apiClient.dio.post(
        ApiEndpoints.applePayPayment,
        data: request.toJson(),
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      print(
        '[SubscriptionService] Apple Pay response status: ${response.statusCode}',
      );
      print('[SubscriptionService] Apple Pay response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApplePayPaymentResponse.fromJson(response.data);
      } else {
        return ApplePayPaymentResponse(
          success: false,
          message: response.data['message'] ?? 'Payment processing failed',
        );
      }
    } on DioException catch (e) {
      print('[SubscriptionService] Apple Pay DioException: ${e.message}');
      print('[SubscriptionService] Response data: ${e.response?.data}');
      return ApplePayPaymentResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Network error occurred',
      );
    } catch (e) {
      print('[SubscriptionService] Apple Pay error: $e');
      return ApplePayPaymentResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Fetch plans from backend and return productId -> planId mapping
  /// Returns empty map on error (will trigger fallback in IAP provider)
  Future<Map<String, int>> fetchPlansMapping() async {
    try {
      print('[SubscriptionService] Fetching plans from backend...');

      // Query oneTimePlans first (contains new subscription plans), fallback to plans
      dynamic responseData;
      try {
        final response = await apiClient.dio.get(
          ApiEndpoints.oneTimePlans,
          options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
        );
        if (response.statusCode == 200 && response.data != null) {
          responseData = response.data;
        }
      } catch (_) {}

      if (responseData == null) {
        final fallbackRes = await apiClient.dio.get(
          ApiEndpoints.plans,
          options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
        );
        if (fallbackRes.statusCode == 200 && fallbackRes.data != null) {
          responseData = fallbackRes.data;
        }
      }

      if (responseData != null) {
        print('\n======================================================');
        print('🔥 [STORE PLANS RAW RESPONSE FOR MAPPING]:');
        print('$responseData');
        print('======================================================\n');

        final plansResponse = PlansListResponse.fromJson(responseData);
        print('[SubscriptionService] Found ${plansResponse.data.length} plans');

        // Build productId -> planId mapping
        final Map<String, int> mapping = {};
        for (final plan in plansResponse.data) {
          print(
            '📦 [STORE PLAN ITEM] id: ${plan.id} | name: "${plan.name}" | product_id: "${plan.productId}" | is_active: ${plan.isActive}',
          );
          if (plan.isActive) {
            if (plan.productId != null && plan.productId!.isNotEmpty) {
              mapping[plan.productId!] = plan.id;
              if (plan.productId!.startsWith('com.')) {
                mapping[plan.productId!.substring(4)] = plan.id;
              } else {
                mapping['com.${plan.productId!}'] = plan.id;
              }
            }

            // Also map by plan name to ensure exact backend ID alignment
            final nameLower = plan.name.toLowerCase();
            if (nameLower.contains('weekend')) mapping[PurchaseProducts.weekendWarriorProductId] = plan.id;
            if (nameLower.contains('scouting')) mapping[PurchaseProducts.justScoutingProductId] = plan.id;
            if (nameLower.contains('seeker')) mapping[PurchaseProducts.seriousSeekerProductId] = plan.id;
            if (nameLower.contains('hunter')) mapping[PurchaseProducts.jobHunterProductId] = plan.id;
            if (nameLower.contains('cram')) mapping[PurchaseProducts.cramSessionProductId] = plan.id;
            if (nameLower.contains('basic')) mapping[PurchaseProducts.basicStudentProductId] = plan.id;
            if (nameLower.contains('mid')) mapping[PurchaseProducts.midStudentProductId] = plan.id;
            if (nameLower.contains('nerd')) mapping[PurchaseProducts.nerdOutProductId] = plan.id;
          }
        }

        print(
          '[SubscriptionService] Plans mapping created with ${mapping.length} entries: $mapping',
        );
        return mapping;
      } else {
        print('[SubscriptionService] Failed to fetch plans for mapping');
        return {};
      }
    } on DioException catch (e) {
      print('[SubscriptionService] Plans fetch DioException: ${e.message}');
      return {};
    } catch (e) {
      print('[SubscriptionService] Plans fetch error: $e');
      return {};
    }
  }

  /// Mark credits as used after successful operations
  /// resourceType: 'quiz' or 'document'
  /// count: number of credits used (typically 1)
  /// description: brief description of the operation
  /// referenceId: optional ID reference for the operation
  /// Retries up to 2 times if the first attempt fails
  Future<bool> markCreditsUsed({
    required String resourceType,
    required int count,
    required String description,
  }) async {
    const maxRetries = 2;
    int attemptCount = 0;

    while (attemptCount <= maxRetries) {
      try {
        attemptCount++;
        print(
          '[SubscriptionService] Marking credits used (attempt $attemptCount/${maxRetries + 1})',
        );

        final response = await apiClient.dio.post(
          ApiEndpoints.markCreditsUsed,
          data: {
            'resource_type': resourceType,
            'count': count,
            'description': description,
            'reference_id': "",
          },
          options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          print(
            '[SubscriptionService] Successfully marked credits used on attempt $attemptCount',
          );
          return true;
        }

        // If status is not success, retry
        print(
          '[SubscriptionService] Failed with status ${response.statusCode}, retrying...',
        );
      } catch (e) {
        print(
          '[SubscriptionService] Error marking credits used (attempt $attemptCount): $e',
        );

        // If this was the last attempt, return false
        if (attemptCount > maxRetries) {
          print(
            '[SubscriptionService] All retry attempts exhausted, marking as failed',
          );
          return false;
        }

        // Wait before retrying (exponential backoff: 1s, 2s)
        final delaySeconds = attemptCount;
        print('[SubscriptionService] Waiting ${delaySeconds}s before retry...');
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    return false;
  }
}
