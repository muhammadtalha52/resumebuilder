import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

import '../models/purchase_product_model.dart';

/// Service to handle in-app purchases for iOS and Android
class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  String? _lastPurchaseError;

  bool get isAvailable => _isAvailable;

  List<ProductDetails> get products => _products;

  List<PurchaseDetails> get purchases => _purchases;

  String? get lastPurchaseError => _lastPurchaseError;

  /// Initialize the IAP service
  Future<bool> initialize() async {
    try {
      _isAvailable = await _iap.isAvailable();

      if (!_isAvailable) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clears pending or unfinished StoreKit transactions to avoid
  /// `PlatformException(storekit_duplicate_product_object, ...)` errors.
  Future<void> clearUnfinishedTransactions({String? productId}) async {
    if (!Platform.isIOS) return;

    // 1. Clear StoreKit 2 unfinished transactions
    try {
      final unfinishedList = await SK2Transaction.unfinishedTransactions();
      for (final tx in unfinishedList) {
        if (productId == null || tx.productId == productId) {
          final txId = int.tryParse(tx.id);
          if (txId != null) {
            await SK2Transaction.finish(txId);
            print(
              '[IAPService] Cleared unfinished StoreKit 2 transaction: ${tx.id} for ${tx.productId}',
            );
          }
        }
      }
    } catch (e) {
      print('[IAPService] Note on StoreKit 2 unfinished transactions: $e');
    }

    // 2. Clear StoreKit 1 unfinished transactions if any
    try {
      final sk1Transactions = await SKPaymentQueueWrapper().transactions();
      for (final tx in sk1Transactions) {
        if (productId == null || tx.payment.productIdentifier == productId) {
          await SKPaymentQueueWrapper().finishTransaction(tx);
          print(
            '[IAPService] Cleared unfinished StoreKit 1 transaction: ${tx.transactionIdentifier}',
          );
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  /// Fetch available products from the store
  Future<bool> loadProducts() async {
    if (!_isAvailable) {
      print('[IAPService] IAP not available');
      return false;
    }

    try {
      final Set<String> productIds = PurchaseProducts.allProductIds.toSet();
      print('[IAPService] Querying products: $productIds');

      final ProductDetailsResponse response = await _iap.queryProductDetails(
        productIds,
      );

      if (response.error != null) {
        print(
          '[IAPService] ERROR loading products: ${response.error!.code} - ${response.error!.message}',
        );
        print('[IAPService] Error details: ${response.error!.details}');
        return false;
      }

      if (response.productDetails.isEmpty) {
        print('[IAPService] No products found in store');
        print('[IAPService] Not found products: ${response.notFoundIDs}');
        return false;
      }

      _products = response.productDetails;
      print('[IAPService] Successfully loaded ${_products.length} products');
      return true;
    } catch (e) {
      print('[IAPService] Exception loading products: $e');
      return false;
    }
  }

  /// Get product details by ID
  ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Maps native store exceptions into clean user-facing messages while keeping
  /// raw stacktraces in logs only.
  String _formatPurchaseError(Object error) {
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      final msg = error.message ?? '';

      if (code == 'storekit_duplicate_product_object') {
        return 'A previous purchase for this plan is still finishing. Please wait a moment and try again.';
      }
      if (code.contains('cancel') || msg.toLowerCase().contains('cancel')) {
        return 'Purchase was cancelled.';
      }
      if (code == 'unknown' ||
          msg.contains('StoreKitError') ||
          msg.contains('Stacktrace:')) {
        return 'Unable to start the App Store purchase right now. If you already subscribed with this Apple ID, please check your App Store subscription settings or try again in a moment.';
      }
      if (msg.trim().isNotEmpty) {
        return msg.trim();
      }
    }
    return 'Failed to initiate purchase. Please check your payment method.';
  }

  /// Purchase a product
  Future<bool> purchaseProduct(ProductDetails product) async {
    _lastPurchaseError = null;
    if (!_isAvailable) {
      _lastPurchaseError = 'In-app purchases are not available on this device';
      return false;
    }

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Subscriptions must use buyNonConsumable; one-off packs use buyConsumable
      final bool isSubscription = product.id.endsWith('_sub') ||
          PurchaseProducts.allProductIds.contains(product.id);

      Future<bool> initiateBuy() => isSubscription
          ? _iap.buyNonConsumable(purchaseParam: purchaseParam)
          : _iap.buyConsumable(purchaseParam: purchaseParam);

      try {
        return await initiateBuy();
      } on PlatformException catch (pe) {
        // If an unfinished transaction for this product was lingering,
        // clear it and retry the purchase once
        if (pe.code == 'storekit_duplicate_product_object') {
          print(
            '[IAPService] Duplicate transaction detected for ${product.id}. Auto-clearing and retrying...',
          );
          await clearUnfinishedTransactions(productId: product.id);
          await Future.delayed(const Duration(milliseconds: 500));
          return await initiateBuy();
        }
        rethrow;
      }
    } catch (e) {
      _lastPurchaseError = _formatPurchaseError(e);
      print('[IAPService] Exception purchasing product: $e');
      return false;
    }
  }

  /// Restore previous purchases (mainly for iOS)
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      return;
    }

    try {
      await _iap.restorePurchases();
    } catch (e) {
      // Handle error
    }
  }

  /// Complete a purchase (mark as consumed)
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (!_isAvailable) {
      return;
    }

    try {
      await _iap.completePurchase(purchase);
    } catch (e) {
      // Handle error
    }
  }

  /// Get purchase token or App Store receipt for backend verification
  Future<String?> getPurchaseToken(PurchaseDetails purchase) async {
    if (Platform.isAndroid) {
      final androidDetails = purchase as GooglePlayPurchaseDetails;
      return androidDetails.billingClientPurchase.purchaseToken;
    } else if (Platform.isIOS) {
      // The backend specifically validates the iOS App Store binary receipt
      // from [[NSBundle mainBundle] appStoreReceiptURL] via Apple's verifyReceipt endpoint,
      // and explicitly rejects StoreKit 2 JWS tokens.
      try {
        final receipt = await SKReceiptManager.retrieveReceiptData();
        if (receipt.isNotEmpty) {
          print(
            '[IAPService] Retrieved native App Store receipt from bundle (length: ${receipt.length})',
          );
          return receipt;
        }
      } catch (e) {
        print('[IAPService] SKReceiptManager.retrieveReceiptData error: $e');
      }

      // If bundle receipt was empty, request StoreKit to refresh receipt from Apple
      try {
        final addition =
            _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        print(
          '[IAPService] Requesting receipt refresh via InAppPurchaseStoreKitPlatformAddition...',
        );
        final refreshed = await addition.refreshPurchaseVerificationData();
        if (refreshed != null && refreshed.serverVerificationData.isNotEmpty) {
          print(
            '[IAPService] Refreshed App Store receipt (length: ${refreshed.serverVerificationData.length})',
          );
          return refreshed.serverVerificationData;
        }
      } catch (e) {
        print('[IAPService] refreshPurchaseVerificationData error: $e');
      }

      // Fallback to serverVerificationData
      print(
        '[IAPService] Falling back to purchase.verificationData.serverVerificationData',
      );
      return purchase.verificationData.serverVerificationData;
    }
    return null;
  }

  /// Get platform name
  String getPlatform() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return 'unknown';
  }

  /// Get pending purchases that need verification
  List<PurchaseDetails> getPendingPurchases() {
    return _purchases
        .where(
          (purchase) =>
              purchase.status == PurchaseStatus.purchased &&
              purchase.pendingCompletePurchase,
        )
        .toList();
  }

  /// Clear completed purchases from local list
  void clearCompletedPurchases() {
    _purchases.removeWhere(
      (purchase) =>
          !purchase.pendingCompletePurchase ||
          purchase.status == PurchaseStatus.canceled ||
          purchase.status == PurchaseStatus.error,
    );
  }

  /// Dispose and clean up
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
