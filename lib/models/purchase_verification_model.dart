import 'user_model.dart';

/// Request model for purchase verification
class PurchaseVerificationRequest {
  final String productId;
  final String purchaseToken;
  final String platform; // 'ios' or 'android'
  final String? transactionDate;

  const PurchaseVerificationRequest({
    required this.productId,
    required this.purchaseToken,
    required this.platform,
    this.transactionDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'purchase_token': purchaseToken,
      'platform': platform,
      if (transactionDate != null) 'transaction_date': transactionDate,
    };
  }

  factory PurchaseVerificationRequest.fromJson(Map<String, dynamic> json) {
    return PurchaseVerificationRequest(
      productId: json['product_id'] as String,
      purchaseToken: json['purchase_token'] as String,
      platform: json['platform'] as String,
      transactionDate: json['transaction_date'] as String?,
    );
  }
}

/// Response model for purchase verification
class PurchaseVerificationResponse {
  final bool success;
  final String? message;
  final User? user;
  final Credits? credits;

  const PurchaseVerificationResponse({
    required this.success,
    this.message,
    this.user,
    this.credits,
  });

  factory PurchaseVerificationResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseVerificationResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      credits: json['credits'] != null
          ? Credits.fromJson(json['credits'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (user != null) 'user': user!.toJson(),
      if (credits != null) 'credits': credits!.toJson(),
    };
  }
}

/// Model for credit information
class Credits {
  final int resumeCredits;
  final int interviewCredits;

  const Credits({required this.resumeCredits, required this.interviewCredits});

  factory Credits.fromJson(Map<String, dynamic> json) {
    return Credits(
      resumeCredits: json['resume_credits'] as int? ?? 0,
      interviewCredits: json['interview_credits'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resume_credits': resumeCredits,
      'interview_credits': interviewCredits,
    };
  }

  Credits copyWith({int? resumeCredits, int? interviewCredits}) {
    return Credits(
      resumeCredits: resumeCredits ?? this.resumeCredits,
      interviewCredits: interviewCredits ?? this.interviewCredits,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Credits &&
        other.resumeCredits == resumeCredits &&
        other.interviewCredits == interviewCredits;
  }

  @override
  int get hashCode => resumeCredits.hashCode ^ interviewCredits.hashCode;

  @override
  String toString() {
    return 'Credits(resumeCredits: $resumeCredits, interviewCredits: $interviewCredits)';
  }
}

/// Request model for consuming credits
class ConsumeCreditsRequest {
  final String type; // 'resume' or 'interview'

  const ConsumeCreditsRequest({required this.type});

  Map<String, dynamic> toJson() {
    return {'type': type};
  }

  factory ConsumeCreditsRequest.fromJson(Map<String, dynamic> json) {
    return ConsumeCreditsRequest(type: json['type'] as String);
  }
}

/// Response model for consuming credits
class ConsumeCreditsResponse {
  final bool success;
  final String? message;
  final int? remainingCredits;

  const ConsumeCreditsResponse({
    required this.success,
    this.message,
    this.remainingCredits,
  });

  factory ConsumeCreditsResponse.fromJson(Map<String, dynamic> json) {
    return ConsumeCreditsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      remainingCredits: json['remaining_credits'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (remainingCredits != null) 'remaining_credits': remainingCredits,
    };
  }
}

/// Request model for Google Pay payment
class GooglePayPaymentRequest {
  final int planId;
  final String paymentToken;
  final String productId;
  final String packageName;
  final String transactionId;
  final String? notes;

  const GooglePayPaymentRequest({
    required this.planId,
    required this.paymentToken,
    required this.productId,
    required this.packageName,
    required this.transactionId,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
      'payment_token': paymentToken,
      'product_id': productId,
      'package_name': packageName,
      'transaction_id': transactionId,
      if (notes != null) 'notes': notes,
    };
  }

  factory GooglePayPaymentRequest.fromJson(Map<String, dynamic> json) {
    return GooglePayPaymentRequest(
      planId: json['plan_id'] as int,
      paymentToken: json['payment_token'] as String,
      productId: json['product_id'] as String,
      packageName: json['package_name'] as String,
      transactionId: json['transaction_id'] as String,
      notes: json['notes'] as String?,
    );
  }
}

/// Response model for Google Pay payment
class GooglePayPaymentResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  const GooglePayPaymentResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory GooglePayPaymentResponse.fromJson(Map<String, dynamic> json) {
    return GooglePayPaymentResponse(
      success: json['success'] as bool? ?? json['status'] == 'success' ?? false,
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (data != null) 'data': data,
    };
  }
}

/// Request model for Apple Pay payment
class ApplePayPaymentRequest {
  final int planId;
  final String receiptData;
  final String transactionId;
  final String? notes;

  const ApplePayPaymentRequest({
    required this.planId,
    required this.receiptData,
    required this.transactionId,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
      'receipt_data': receiptData,
      'transaction_id': transactionId,
      if (notes != null) 'notes': notes,
    };
  }

  factory ApplePayPaymentRequest.fromJson(Map<String, dynamic> json) {
    return ApplePayPaymentRequest(
      planId: json['plan_id'] as int,
      receiptData: json['receipt_data'] as String,
      transactionId: json['transaction_id'] as String,
      notes: json['notes'] as String?,
    );
  }
}

/// Response model for Apple Pay payment
class ApplePayPaymentResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  const ApplePayPaymentResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ApplePayPaymentResponse.fromJson(Map<String, dynamic> json) {
    return ApplePayPaymentResponse(
      success: json['success'] as bool? ?? json['status'] == 'success' ?? false,
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (data != null) 'data': data,
    };
  }
}
