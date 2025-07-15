class SubscriptionErrorHandler {
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // RevenueCat specific errors
    if (errorString.contains('revenuecat not initialized')) {
      return 'Payment system is initializing. Please try again in a moment.';
    }
    if (errorString.contains('no offerings available')) {
      return 'Subscription options are currently unavailable. Please try again later.';
    }
    if (errorString.contains('no package found')) {
      return 'The selected subscription plan is not available. Please try a different option.';
    }
    if (errorString.contains('user cancelled') ||
        errorString.contains('user canceled')) {
      return 'Purchase was cancelled.';
    }
    if (errorString.contains('store problem') ||
        errorString.contains('billing unavailable')) {
      return 'App Store billing is currently unavailable. Please try again later.';
    }
    if (errorString.contains('item unavailable') ||
        errorString.contains('product not available')) {
      return 'This subscription is temporarily unavailable. Please try again later.';
    }
    if (errorString.contains('payment invalid') ||
        errorString.contains('payment declined')) {
      return 'Payment was declined. Please check your payment method and try again.';
    }
    if (errorString.contains('insufficient funds')) {
      return 'Insufficient funds. Please update your payment method and try again.';
    }

    // Network and connection errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('internet')) {
      return 'Network connection error. Please check your internet and try again.';
    }
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // Generic payment/subscription errors
    if (errorString.contains('purchase') && errorString.contains('failed')) {
      return 'Purchase failed. Please try again or contact support if the issue persists.';
    }
    if (errorString.contains('subscription') && errorString.contains('error')) {
      return 'Subscription error. Please try again or contact support.';
    }

    // If no specific pattern matches, return a generic user-friendly message
    return 'Unable to complete subscription. Please try again or contact support if the issue persists.';
  }
}
