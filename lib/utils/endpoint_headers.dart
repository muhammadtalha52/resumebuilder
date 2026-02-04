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
  static const String baseUrl = 'https://api.skillresy.com/api';
  static const String resumeModuleBaseUrl = 'https://ai.skillresy.com/';
  static const String interviewModuleBaseUrl = 'https://ia.skillresy.com/api/';
  static const String quizModuleBaseUrl = 'https://quiz.skillresy.com/';

  static const String register = '/auth/register/';
  static const String registerSimple = '/auth/registerWithEmailAndPassword/';
  static const String login = '/auth/login/';
  static const String isEmailExists = '/auth/is_email_exists/';
  static const String forgotPassword = '/auth/forgot-password/';
  static const String profileUpdate = '/auth/profile/';
  static const String uploadProfilePhoto = '/auth/upload-profile-image/';
  static const String deleteAccount =
      '/auth/delete-user-data/'; // Append user ID
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

  // Invite Friends
  static const String sendInvite = '/auth/invites/send/';
  static const String getInvites = '/auth/invites/';
}
