import 'package:in_app_review/in_app_review.dart';
import 'app_preferences.dart';

class InAppReviewService {
  final InAppReview _inAppReview = InAppReview.instance;

  /// Request in-app review (only shows once across all triggers)
  /// Triggers: first resume, first interview, or first quiz - whichever comes first
  /// Returns true if review was requested, false otherwise
  Future<bool> requestReview() async {
    try {
      // Check if we've already requested review
      final hasRequested = await AppPreferences.hasRequestedInAppReview();
      if (hasRequested) {
        print('⭐ In-app review already requested');
        return false;
      }

      // Check if in-app review is available
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        print('⭐ In-app review not available on this device');
        return false;
      }

      // Request review
      print('⭐ Requesting in-app review');
      await _inAppReview.requestReview();
      //await _inAppReview.openStoreListing(appStoreId: '6755155918');

      // Mark as requested
      await AppPreferences.setInAppReviewRequested();
      print('✅ In-app review requested successfully');
      return true;
    } catch (e) {
      print('❌ Error requesting in-app review: $e');
      return false;
    }
  }
}
