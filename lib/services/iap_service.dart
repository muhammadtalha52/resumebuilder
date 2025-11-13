import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import '../models/purchase_product_model.dart';

/// Service to handle in-app purchases for iOS and Android
class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];

  bool get isAvailable => _isAvailable;

  List<ProductDetails> get products => _products;

  List<PurchaseDetails> get purchases => _purchases;

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

  /// Purchase a product
  Future<bool> purchaseProduct(ProductDetails product) async {
    if (!_isAvailable) {
      return false;
    }

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // All products are consumable
      final bool success = await _iap.buyConsumable(
        purchaseParam: purchaseParam,
      );

      return success;
    } catch (e) {
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

  /// Get purchase token for verification
  String? getPurchaseToken(PurchaseDetails purchase) {
    if (Platform.isAndroid) {
      final androidDetails = purchase as GooglePlayPurchaseDetails;
      return androidDetails.billingClientPurchase.purchaseToken;
    } else if (Platform.isIOS) {
      // Handle both StoreKit 1 and StoreKit 2
      if (purchase is AppStorePurchaseDetails) {
        // StoreKit 1
        return purchase.verificationData.serverVerificationData;
      } else if (purchase is SK2PurchaseDetails) {
        // StoreKit 2
        return purchase.verificationData.serverVerificationData;
      }
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
