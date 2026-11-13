/// Model representing a plan from the backend API
class BackendPlanModel {
  final int id;
  final String name;
  final String planType;
  final String? productId;
  final String price;
  final String? billingInterval; // 'week' or 'month'
  final int resumeCount;
  final int interviewCount;
  final int quizCount;
  final int documentUploadCount;
  final int askScoutCount;
  final int trialDays;
  final int trialResumeCount;
  final int trialInterviewCount;
  final int trialQuizCount;
  final int trialDocumentUploadCount;
  final bool isSubscription;
  final bool isActive;
  final bool isRecommended;

  const BackendPlanModel({
    required this.id,
    required this.name,
    this.planType = '',
    this.productId,
    required this.price,
    this.billingInterval,
    this.resumeCount = 0,
    this.interviewCount = 0,
    this.quizCount = 0,
    this.documentUploadCount = 0,
    this.askScoutCount = 0,
    this.trialDays = 0,
    this.trialResumeCount = 0,
    this.trialInterviewCount = 0,
    this.trialQuizCount = 0,
    this.trialDocumentUploadCount = 0,
    this.isSubscription = false,
    this.isActive = true,
    this.isRecommended = false,
  });

  BackendPlanModel copyWith({
    int? id,
    String? name,
    String? planType,
    String? productId,
    String? price,
    String? billingInterval,
    int? resumeCount,
    int? interviewCount,
    int? quizCount,
    int? documentUploadCount,
    int? askScoutCount,
    int? trialDays,
    int? trialResumeCount,
    int? trialInterviewCount,
    int? trialQuizCount,
    int? trialDocumentUploadCount,
    bool? isSubscription,
    bool? isActive,
    bool? isRecommended,
  }) {
    return BackendPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      planType: planType ?? this.planType,
      productId: productId ?? this.productId,
      price: price ?? this.price,
      billingInterval: billingInterval ?? this.billingInterval,
      resumeCount: resumeCount ?? this.resumeCount,
      interviewCount: interviewCount ?? this.interviewCount,
      quizCount: quizCount ?? this.quizCount,
      documentUploadCount: documentUploadCount ?? this.documentUploadCount,
      askScoutCount: askScoutCount ?? this.askScoutCount,
      trialDays: trialDays ?? this.trialDays,
      trialResumeCount: trialResumeCount ?? this.trialResumeCount,
      trialInterviewCount: trialInterviewCount ?? this.trialInterviewCount,
      trialQuizCount: trialQuizCount ?? this.trialQuizCount,
      trialDocumentUploadCount:
          trialDocumentUploadCount ?? this.trialDocumentUploadCount,
      isSubscription: isSubscription ?? this.isSubscription,
      isActive: isActive ?? this.isActive,
      isRecommended: isRecommended ?? this.isRecommended,
    );
  }

  bool get isWeekly {
    final interval = billingInterval?.toLowerCase();
    if (interval == 'week') return true;
    if (interval == 'month') return false;
    final nameLower = name.toLowerCase();
    final pId = productId?.toLowerCase() ?? '';
    return nameLower.contains('weekend') ||
        nameLower.contains('cram') ||
        pId.contains('weekend') ||
        pId.contains('cram') ||
        id == 11 ||
        id == 21;
  }

  bool get isMonthly => !isWeekly;
  bool get hasTrial => trialDays > 0;

  String get formattedBillingInterval => isWeekly ? 'week' : 'month';

  String get formattedPrice {
    final cleanPrice = price.replaceAll('\$', '');
    return '\$$cleanPrice / $formattedBillingInterval';
  }

  /// Generates dynamic feature list according to documentation
  List<String> get features {
    final list = <String>[];
    final intervalStr = isWeekly ? ' a week' : ' a month';

    // Candidate features
    if (resumeCount > 0) {
      list.add('$resumeCount Resumes $intervalStr');
    }
    if (interviewCount > 0) {
      list.add('$interviewCount Live Sessions $intervalStr');
    }
    if (askScoutCount > 0) {
      list.add('$askScoutCount Ask Scout questions $intervalStr');
    }

    // Student features
    if (quizCount > 0) {
      list.add(
        '$quizCount Guided Study Sessions (with Custom Quiz) $intervalStr',
      );
    }
    if (documentUploadCount > 0) {
      list.add('$documentUploadCount Document uploads $intervalStr');
    }

    // Student extras
    if (quizCount > 0 || documentUploadCount > 0) {
      list.add('Quiz history & progress tracking included');
    }
    // Trial line for every plan with hasTrial
    if (hasTrial && isSubscription) {
      list.add('$trialDays-day free trial included');
    }

    return list;
  }

  factory BackendPlanModel.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    final nameLower = name.toLowerCase();
    final pId = (json['product_id'] ?? '').toString().toLowerCase();
    final id = (json['id'] as num?)?.toInt() ?? 0;
    final isRec =
        json['is_recommended'] == true ||
        nameLower.contains('best value') ||
        nameLower.contains('serious seeker') ||
        nameLower.contains('nerd out');

    // Ensure billing interval is resolved accurately for all 8 plans
    String? interval = json['billing_interval']?.toString();
    if (interval == null || interval.isEmpty) {
      if (nameLower.contains('weekend') ||
          nameLower.contains('cram') ||
          pId.contains('weekend') ||
          pId.contains('cram') ||
          id == 11 ||
          id == 21) {
        interval = 'week';
      } else {
        interval = 'month';
      }
    }

    return BackendPlanModel(
      id: id,
      name: name,
      planType: json['plan_type']?.toString() ?? '',
      productId: json['product_id']?.toString(),
      price: json['price']?.toString() ?? '0.00',
      billingInterval: interval,
      resumeCount: (json['resume_count'] as num?)?.toInt() ?? 0,
      interviewCount: (json['interview_count'] as num?)?.toInt() ?? 0,
      quizCount: (json['quiz_count'] as num?)?.toInt() ?? 0,
      documentUploadCount:
          (json['document_upload_count'] as num?)?.toInt() ?? 0,
      askScoutCount: (json['ask_scout_count'] as num?)?.toInt() ?? 0,
      trialDays: (json['trial_days'] as num?)?.toInt() ?? 0,
      trialResumeCount: (json['trial_resume_count'] as num?)?.toInt() ?? 0,
      trialInterviewCount:
          (json['trial_interview_count'] as num?)?.toInt() ?? 0,
      trialQuizCount: (json['trial_quiz_count'] as num?)?.toInt() ?? 0,
      trialDocumentUploadCount:
          (json['trial_document_upload_count'] as num?)?.toInt() ?? 0,
      isSubscription: json['is_subscription'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      isRecommended: isRec,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plan_type': planType,
      'product_id': productId,
      'price': price,
      'billing_interval': billingInterval,
      'resume_count': resumeCount,
      'interview_count': interviewCount,
      'quiz_count': quizCount,
      'document_upload_count': documentUploadCount,
      'ask_scout_count': askScoutCount,
      'trial_days': trialDays,
      'trial_resume_count': trialResumeCount,
      'trial_interview_count': trialInterviewCount,
      'trial_quiz_count': trialQuizCount,
      'trial_document_upload_count': trialDocumentUploadCount,
      'is_subscription': isSubscription,
      'is_active': isActive,
    };
  }

  @override
  String toString() {
    return 'BackendPlanModel(id: $id, name: $name, price: $price, interval: $billingInterval)';
  }
}

/// Response model for plans list API
class PlansListResponse {
  final String status;
  final String message;
  final List<BackendPlanModel> data;

  const PlansListResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PlansListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final List<BackendPlanModel> items = [];
    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          items.add(BackendPlanModel.fromJson(item));
        }
      }
    }

    return PlansListResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: items,
    );
  }
}
