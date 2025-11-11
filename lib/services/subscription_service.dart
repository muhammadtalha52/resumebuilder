import 'package:dio/dio.dart';
import '../models/purchase_verification_model.dart';
import '../models/backend_plan_model.dart';
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
  Future<Credits?> getCredits() async {
    try {
      final response = await apiClient.dio.get(
        ApiEndpoints.getCredits,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200) {
        return Credits.fromJson(response.data);
      } else {
        return null;
      }
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Consume a credit (resume or interview)
  Future<ConsumeCreditsResponse> consumeCredit(String type) async {
    try {
      final request = ConsumeCreditsRequest(type: type);

      final response = await apiClient.dio.post(
        ApiEndpoints.consumeCredit,
        data: request.toJson(),
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ConsumeCreditsResponse.fromJson(response.data);
      } else {
        return ConsumeCreditsResponse(
          success: false,
          message: response.data['message'] ?? 'Failed to consume credit',
        );
      }
    } on DioException catch (e) {
      return ConsumeCreditsResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Network error occurred',
      );
    } catch (e) {
      return ConsumeCreditsResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

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

  /// Check if user has enough credits for an operation
  Future<bool> hasCredits(String type) async {
    try {
      final credits = await getCredits();
      if (credits == null) return false;

      if (type == 'resume') {
        return credits.resumeCredits > 0;
      } else if (type == 'interview') {
        return credits.interviewCredits > 0;
      }

      return false;
    } catch (_) {
      return false;
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

  /// Fetch plans from backend and return productId -> planId mapping
  /// Returns empty map on error (will trigger fallback in IAP provider)
  Future<Map<String, int>> fetchPlansMapping() async {
    try {
      print('[SubscriptionService] Fetching plans from backend...');

      final response = await apiClient.dio.get(
        ApiEndpoints.plans,
        options: Options(headers: {WAInterceptorHeaders.requiresToken: true}),
      );

      print(
        '[SubscriptionService] Plans response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final plansResponse = PlansListResponse.fromJson(response.data);
        print('[SubscriptionService] Found ${plansResponse.data.length} plans');

        // Build productId -> planId mapping
        final Map<String, int> mapping = {};
        for (final plan in plansResponse.data) {
          if (plan.isActive) {
            mapping[plan.productId] = plan.id;
            print(
              '[SubscriptionService] Mapped: ${plan.productId} -> ${plan.id}',
            );
          }
        }

        print(
          '[SubscriptionService] Plans mapping created with ${mapping.length} entries',
        );
        return mapping;
      } else {
        print(
          '[SubscriptionService] Failed to fetch plans: ${response.statusCode}',
        );
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
}
