import 'package:flutter_dotenv/flutter_dotenv.dart';

class WAInterceptorHeaders {
  static String requiresToken = 'requiresToken';
  static String authorization = 'Authorization';
  static String xRequestWith = 'X-Requested-With';
  static String contentType = 'Content-Type';
  static String accept = 'Accept';
}

class ApiEndpoints {
  ///Dev urls
  // static const String baseUrl = 'https://api-dev.skillresy.com/api';
  // static const String resumeModuleBaseUrl = 'https://ai-dev.skillresy.com';
  // static const String interviewModuleBaseUrl =
  //     'https://ia-dev.skillresy.com/api/'; //
  // static const String quizModuleBaseUrl = 'https://quiz-dev.skillresy.com';

  ///Prod Urls
  static String get baseUrl => (dotenv.isInitialized ? dotenv.env['API_BASE_URL'] : null) ?? 'https://api.skillresy.com/api';
  static String get formattedServerBaseUrl {
    final url = baseUrl;
    if (url.contains('api-dev.skillresy.com')) {
      return 'Dev Server: $url';
    } else if (url.contains('api.skillresy.com')) {
      return 'Prod Server: $url';
    } else {
      return url;
    }
  }
  static const String resumeModuleBaseUrl = 'https://ai.skillresy.com/';
  static const String interviewModuleBaseUrl = 'https://ia.skillresy.com/api/';
  static const String quizModuleBaseUrl = 'https://quiz.skillresy.com/';

  static const String register = '/auth/register/';
  static const String registerSimple = '/auth/registerWithEmailAndPassword/';
  static const String trackEvent = '/auth/track-event/';
  static const String login = '/auth/login/';
  static const String logout = '/auth/logout/';
  static const String registerDevice = '/notifications/devices/';
  static const String isEmailExists = '/auth/is_email_exists/';
  static const String forgotPassword = '/auth/forgot-password/';
  static const String profileUpdate = '/auth/profile/';
  static const String uploadProfilePhoto = '/auth/upload-profile-image/';
  static const String deleteAccount = '/auth/delete-user-data/';
  static const String aiConsent = '/auth/ai-consent/';
  static const String educationData =
      '/resume/degree-types-subject-institutes/';
  static const String sessionStart = '/session/start';
  static const String saveInterviewData = '/interview/interviews/';
  static const String folders = '/auth/folders/';
  static const String folderItems = '/auth/folder-items/';
  static const String generateQuiz = '/generate-quiz-from-urls';
  static const String viewS3Assets = '/auth/view-s3-assets/';
  static const String quizAttempts = '/auth/quiz-attempts/';
  static const String quizAttemptsList = '/auth/quiz-attempts/list/';

  // In-App Purchase Endpoints
  static const String verifyPurchase = '/subscription/verify-purchase/';
  static const String restorePurchases = '/subscription/restore/';

  // Plan Payment Endpoints
  static const String googlePayPayment = '/plan/payments/google-pay/';
  static const String applePayPayment = '/plan/payments/apple-pay/';
  static const String planAllocation = '/plan/allocation/';
  static const String plans = '/plan/plans/';
  static const String markCreditsUsed = '/plan/allocation/use/';

  // Stripe Subscription Endpoints
  static const String oneTimePlans = '/plan/plans/one-time/';
  static const String subscription = '/plan/subscription/';
  static const String subscriptionCheckout = '/plan/subscription/checkout/';
  static const String subscriptionVerify = '/plan/subscription/verify/';
  static const String subscriptionUpdate = '/plan/subscription/update/';
  static const String subscriptionCancel = '/plan/subscription/cancel/';

  /// Returns origin URL Stripe redirects user to. Dev: dev-app.skillresy.com, Prod: app.skillresy.com
  static String get stripeReturnOrigin {
    final url = baseUrl.toLowerCase();
    if (url.contains('api-dev') || url.contains('dev')) {
      return 'https://dev-app.skillresy.com';
    }
    return 'https://app.skillresy.com';
  }

  // Invite Friends
  static const String sendInvite = '/auth/invites/send/';
  static const String getInvites = '/auth/invites/';

  // Job Matching
  static const String matchingJobs = '/jobs/';
  static const String applyToJob = '/jobs/apply/';
}
