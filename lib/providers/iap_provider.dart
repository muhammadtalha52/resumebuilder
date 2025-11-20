import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/purchase_verification_model.dart';
import '../services/iap_service.dart';
import '../services/subscription_service.dart';
import '../services/api_client.dart';
import 'usage_provider.dart';

// IAP State
class IAPState extends Equatable {
  const IAPState({
    this.isLoading = false,
    this.isInitialized = false,
    this.products = const [],
    this.isPurchasing = false,
    this.isInitiatingCheckout = false,
    this.isLoadingPlansMapping = false,
    this.error,
    this.successMessage,
  });

  final bool isLoading;
  final bool isInitialized;
  final List<ProductDetails> products;
  final bool isPurchasing;
  final bool isInitiatingCheckout;
  final bool isLoadingPlansMapping;
  final String? error;
  final String? successMessage;

  IAPState copyWith({
    bool? isLoading,
    bool? isInitialized,
    List<ProductDetails>? products,
    bool? isPurchasing,
    bool? isInitiatingCheckout,
    bool? isLoadingPlansMapping,
    String? error,
    String? successMessage,
  }) {
    return IAPState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      products: products ?? this.products,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isInitiatingCheckout: isInitiatingCheckout ?? this.isInitiatingCheckout,
      isLoadingPlansMapping:
          isLoadingPlansMapping ?? this.isLoadingPlansMapping,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isInitialized,
    products,
    isPurchasing,
    isInitiatingCheckout,
    isLoadingPlansMapping,
    error,
    successMessage,
  ];
}

// IAP State Notifier
class IAPNotifier extends StateNotifier<IAPState> {
  IAPNotifier(this._ref) : super(const IAPState()) {
    _initialize();
  }

  final Ref _ref;
  final IAPService _iapService = IAPService();
  late final SubscriptionService _subscriptionService;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Map<String, int> _productIdToPlanId = {};

  /// Initialize IAP service and load products
  Future<void> _initialize() async {
    print('[IAPProvider] Initializing IAP...');
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    try {
      // Initialize subscription service
      final apiClient = APIClient();
      _subscriptionService = SubscriptionService(apiClient);

      // Initialize IAP
      print('[IAPProvider] Checking IAP availability...');
      final isAvailable = await _iapService.initialize();
      print('[IAPProvider] IAP available: $isAvailable');

      if (!mounted) return;
      if (!isAvailable) {
        print('[IAPProvider] ERROR: IAP not available on this device');
        state = state.copyWith(
          isLoading: false,
          error: 'In-app purchases are not available on this device',
        );
        return;
      }

      // Load products from store
      print('[IAPProvider] Loading products from store...');
      final productsLoaded = await _iapService.loadProducts();
      print('[IAPProvider] Products loaded: $productsLoaded');
      print('[IAPProvider] Number of products: ${_iapService.products.length}');

      if (!mounted) return;
      if (productsLoaded) {
        for (var product in _iapService.products) {
          print(
            '[IAPProvider] - Product: ${product.id} | ${product.title} | ${product.price}',
          );
        }

        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          products: _iapService.products,
        );

        print('[IAPProvider] IAP initialized successfully');

        // Start listening to purchase updates
        _listenToPurchaseUpdates();

        // Check for pending purchases
        _processPendingPurchases();
      } else {
        print('[IAPProvider] ERROR: Failed to load products');
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load available products',
        );
      }
    } catch (e) {
      print('[IAPProvider] ERROR during initialization: $e');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize purchases: ${e.toString()}',
      );
    }
  }

  /// Listen to purchase updates from the store
  void _listenToPurchaseUpdates() {
    final iap = InAppPurchase.instance;
    _purchaseSubscription = iap.purchaseStream.listen(
      (purchaseDetailsList) {
        _handlePurchaseUpdates(purchaseDetailsList);
      },
      onDone: () {
        _purchaseSubscription?.cancel();
      },
      onError: (error) {
        if (!mounted) return;
        state = state.copyWith(
          isPurchasing: false,
          error: 'Purchase error: ${error.toString()}',
        );
      },
    );
  }

  /// Handle purchase updates
  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchase in purchaseDetailsList) {
      await _processPurchase(purchase);
    }
  }

  /// Process individual purchase
  Future<void> _processPurchase(PurchaseDetails purchase) async {
    print('\n========== PURCHASE DETAILS ==========');
    print('[IAPProvider] Purchase Status: ${purchase.status}');
    print('[IAPProvider] Product ID: ${purchase.productID}');
    print('[IAPProvider] Purchase ID: ${purchase.purchaseID}');
    print('[IAPProvider] Transaction Date: ${purchase.transactionDate}');
    print(
      '[IAPProvider] Pending Complete: ${purchase.pendingCompletePurchase}',
    );
    print(
      '[IAPProvider] Verification Data Source: ${purchase.verificationData.source}',
    );
    print(
      '[IAPProvider] Server Verification Data: ${purchase.verificationData.serverVerificationData}',
    );
    print(
      '[IAPProvider] Local Verification Data: ${purchase.verificationData.localVerificationData}',
    );
    print('======================================\n');

    if (purchase.status == PurchaseStatus.pending) {
      // Purchase is pending
      print('[IAPProvider] Purchase status is PENDING');
      state = state.copyWith(isPurchasing: true);
    } else if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      // Verify purchase with backend
      print(
        '[IAPProvider] Purchase status is ${purchase.status == PurchaseStatus.purchased ? "PURCHASED" : "RESTORED"}',
      );
      await _verifyPurchase(purchase);
    } else if (purchase.status == PurchaseStatus.error) {
      // Purchase failed
      print(
        '[IAPProvider] Purchase status is ERROR: ${purchase.error?.message}',
      );
      state = state.copyWith(
        isPurchasing: false,
        error: purchase.error?.message ?? 'Purchase failed',
      );

      // Complete the purchase to remove from pending
      if (purchase.pendingCompletePurchase) {
        await _iapService.completePurchase(purchase);
      }
    } else if (purchase.status == PurchaseStatus.canceled) {
      // Purchase canceled by user
      print('[IAPProvider] Purchase status is CANCELED');
      state = state.copyWith(isPurchasing: false, error: null);

      // Complete the purchase to remove from pending
      if (purchase.pendingCompletePurchase) {
        await _iapService.completePurchase(purchase);
      }
    }
  }

  /// Map product ID to plan ID
  /// First tries to get from backend mapping, then falls back to hardcoded
  int _getPlanIdFromProductId(String productId) {
    // Try to get from backend mapping first
    if (_productIdToPlanId.containsKey(productId)) {
      final planId = _productIdToPlanId[productId]!;
      print(
        '[IAPProvider] Mapped $productId to plan ID $planId (from backend)',
      );
      return planId;
    }

    // Fallback to hardcoded mapping
    print('[IAPProvider] Using fallback mapping for $productId');

    if (productId.contains('candidate.basic')) {
      return 1;
    } else if (productId.contains('candidate.pro')) {
      return 2;
    } else if (productId.contains('candidate.enterprise')) {
      return 3;
    } else if (productId.contains('student.basic')) {
      return 4;
    } else if (productId.contains('student.pro')) {
      return 5;
    } else if (productId.contains('student.enterprise')) {
      return 6;
    }

    print(
      '[IAPProvider] WARNING: Unexpected product ID: $productId - defaulting to Basic (plan 1)',
    );
    return 1; // Default to basic
  }

  /// Verify purchase with backend
  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    // Show loading during verification
    state = state.copyWith(isPurchasing: true);

    try {
      print('\n========== VERIFYING PURCHASE ==========');
      final purchaseToken = _iapService.getPurchaseToken(purchase);
      final platform = _iapService.getPlatform();

      print('[IAPProvider] Extracted Purchase Token: $purchaseToken');
      print('[IAPProvider] Platform: $platform');

      if (purchaseToken == null) {
        print('[IAPProvider] ERROR: Purchase token is NULL');
        state = state.copyWith(
          isPurchasing: false,
          error: 'Failed to get purchase token',
        );
        return;
      }

      // For Android, use Google Pay endpoint
      if (platform == 'android') {
        final planId = _getPlanIdFromProductId(purchase.productID);
        final transactionId = purchase.purchaseID ?? 'unknown';

        final request = GooglePayPaymentRequest(
          planId: planId,
          paymentToken: purchaseToken,
          productId: purchase.productID,
          packageName: 'com.skillresy.app',
          // Your app's package name
          transactionId: transactionId,
          notes: 'Payment from Android app for plan $planId',
        );

        print('[IAPProvider] Google Pay Payment Request:');
        print('  - Plan ID: ${request.planId}');
        print('  - Product ID: ${request.productId}');
        print('  - Package Name: ${request.packageName}');
        print('  - Payment Token: ${request.paymentToken}');
        print('  - Transaction ID: ${request.transactionId}');
        print('[IAPProvider] Sending payment request to backend...');

        final response = await _subscriptionService.processGooglePayPayment(
          request,
        );

        print('[IAPProvider] Backend Response:');
        print('  - Success: ${response.success}');
        print('  - Message: ${response.message}');
        print('  - Data: ${response.data}');
        print('========================================\n');

        if (response.success) {
          // Complete the purchase
          await _iapService.completePurchase(purchase);

          // Update state
          state = state.copyWith(
            isPurchasing: false,
            successMessage:
                'Purchase successful! Your plan has been activated.',
            error: null,
          );

          // Refresh usage allocation from backend
          await _ref.read(usageProvider.notifier).fetchUsageAllocation();
        } else {
          state = state.copyWith(
            isPurchasing: false,
            error: response.message ?? 'Payment processing failed',
          );

          // Still complete the purchase to avoid stuck state
          if (purchase.pendingCompletePurchase) {
            await _iapService.completePurchase(purchase);
          }
        }
      } else {
        // For iOS, use Apple Pay endpoint
        final planId = _getPlanIdFromProductId(purchase.productID);
        final transactionId = purchase.purchaseID ?? 'unknown';

        final request = ApplePayPaymentRequest(
          planId: planId,
          receiptData: purchaseToken,
          transactionId: transactionId,
          notes: 'Payment from iOS app for plan $planId',
        );

        print('[IAPProvider] Apple Pay Payment Request:');
        print('  - Plan ID: ${request.planId}');
        print('  - Receipt Data: ${request.receiptData.substring(0, 50)}...');
        print('  - Transaction ID: ${request.transactionId}');
        print('[IAPProvider] Sending payment request to backend...');

        final response = await _subscriptionService.processApplePayPayment(
          request,
        );

        print('[IAPProvider] Backend Response:');
        print('  - Success: ${response.success}');
        print('  - Message: ${response.message}');
        print('  - Data: ${response.data}');
        print('========================================\n');

        if (response.success) {
          // Complete the purchase
          await _iapService.completePurchase(purchase);

          // Update state
          state = state.copyWith(
            isPurchasing: false,
            successMessage:
                'Purchase successful! Your plan has been activated.',
            error: null,
          );

          // Refresh usage allocation from backend
          await _ref.read(usageProvider.notifier).fetchUsageAllocation();
        } else {
          state = state.copyWith(
            isPurchasing: false,
            error: response.message ?? 'Payment processing failed',
          );

          // Still complete the purchase to avoid stuck state
          if (purchase.pendingCompletePurchase) {
            await _iapService.completePurchase(purchase);
          }
        }
      }
    } catch (e) {
      print('[IAPProvider] Verification error: $e');
      state = state.copyWith(
        isPurchasing: false,
        error: 'Verification error: ${e.toString()}',
      );

      // Complete the purchase even on error
      if (purchase.pendingCompletePurchase) {
        await _iapService.completePurchase(purchase);
      }
    }
  }

  /// Check for and process any pending purchases
  Future<void> _processPendingPurchases() async {
    final pendingPurchases = _iapService.getPendingPurchases();

    for (var purchase in pendingPurchases) {
      await _processPurchase(purchase);
    }
  }

  /// Purchase a product
  Future<void> purchaseProduct(String productId) async {
    print('[IAPProvider] Purchase requested for product: $productId');
    print(
      '[IAPProvider] Available products: ${_iapService.products.map((p) => p.id).toList()}',
    );

    // Set isInitiatingCheckout for button loading (not full-screen overlay)
    state = state.copyWith(isInitiatingCheckout: true, error: null);

    try {
      final product = _iapService.getProductById(productId);

      if (product == null) {
        print('[IAPProvider] ERROR: Product not found: $productId');
        state = state.copyWith(
          isInitiatingCheckout: false,
          error: 'Product not found. Please try again later.',
        );
        return;
      }

      print('[IAPProvider] Product found: ${product.title} (${product.id})');
      print('[IAPProvider] Initiating purchase...');

      final success = await _iapService.purchaseProduct(product);

      print('[IAPProvider] Purchase initiation result: $success');

      if (!success) {
        state = state.copyWith(
          isInitiatingCheckout: false,
          error:
              'Failed to initiate purchase. Please check your payment method.',
        );
      } else {
        // Checkout sheet opened successfully, clear button loading
        state = state.copyWith(isInitiatingCheckout: false);
      }

      // State will be maintained by purchase stream listener
    } catch (e) {
      print('[IAPProvider] Purchase error: $e');
      state = state.copyWith(
        isInitiatingCheckout: false,
        error: 'Purchase failed: ${e.toString()}',
      );
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _iapService.restorePurchases();

      // Process will be handled by purchase stream listener
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Restore initiated. Please wait...',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Restore failed: ${e.toString()}',
      );
    }
  }

  /// Get product by ID
  ProductDetails? getProductById(String productId) {
    return _iapService.getProductById(productId);
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Load plans mapping from backend
  /// Called when plans screen opens
  Future<void> loadPlansMapping() async {
    if (!mounted) return;
    state = state.copyWith(isLoadingPlansMapping: true);

    try {
      print('[IAPProvider] Loading plans mapping from backend...');
      final mapping = await _subscriptionService.fetchPlansMapping();

      if (!mounted) return;

      if (mapping.isNotEmpty) {
        _productIdToPlanId = mapping;
        print('[IAPProvider] Plans mapping loaded: $_productIdToPlanId');
      } else {
        print('[IAPProvider] No plans mapping loaded, will use fallback');
      }

      state = state.copyWith(isLoadingPlansMapping: false);
    } catch (e) {
      print('[IAPProvider] Error loading plans mapping: $e');
      if (!mounted) return;
      // Silent fail - will use fallback in _getPlanIdFromProductId
      state = state.copyWith(isLoadingPlansMapping: false);
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _iapService.dispose();
    super.dispose();
  }
}

// IAP Provider
final iapProvider = StateNotifierProvider<IAPNotifier, IAPState>((ref) {
  return IAPNotifier(ref);
});
