import 'package:intl/intl.dart';


/// Current status of the Stripe subscription
enum StripeSubscriptionStatus {
  trialing,
  active,
  pastDue,
  canceled,
  unknown;

  static StripeSubscriptionStatus fromString(String? value) {
    switch (value?.toLowerCase().replaceAll('_', '')) {
      case 'trialing':
        return StripeSubscriptionStatus.trialing;
      case 'active':
        return StripeSubscriptionStatus.active;
      case 'pastdue':
        return StripeSubscriptionStatus.pastDue;
      case 'canceled':
      case 'cancelled':
        return StripeSubscriptionStatus.canceled;
      default:
        return StripeSubscriptionStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case StripeSubscriptionStatus.trialing:
        return 'In Trial';
      case StripeSubscriptionStatus.active:
        return 'Active';
      case StripeSubscriptionStatus.pastDue:
        return 'Past Due';
      case StripeSubscriptionStatus.canceled:
        return 'Canceled';
      case StripeSubscriptionStatus.unknown:
        return 'Inactive';
    }
  }
}

/// Plan information embedded inside subscription object
class SubscriptionPlanSummary {
  final int id;
  final String name;
  final String price;
  final String? billingInterval;
  final int trialDays;

  const SubscriptionPlanSummary({
    required this.id,
    required this.name,
    required this.price,
    this.billingInterval,
    this.trialDays = 7,
  });

  bool get isWeekly => billingInterval?.toLowerCase() == 'week';
  bool get isMonthly => billingInterval?.toLowerCase() == 'month';

  String get formattedPrice {
    final cleanPrice = price.replaceAll('\$', '');
    final interval = isWeekly ? 'week' : (isMonthly ? 'month' : billingInterval ?? 'month');
    return '\$$cleanPrice/$interval';
  }

  factory SubscriptionPlanSummary.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      price: json['price']?.toString() ?? '0.00',
      billingInterval: json['billing_interval']?.toString(),
      trialDays: (json['trial_days'] as num?)?.toInt() ?? 7,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'billing_interval': billingInterval,
    };
  }
}

/// Stripe Subscription object
class StripeSubscription {
  final int id;
  final StripeSubscriptionStatus status;
  final String rawStatus;
  final SubscriptionPlanSummary plan;
  final SubscriptionPlanSummary? nextPlan;
  final bool inTrial;
  final DateTime? trialEnd;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final DateTime? creditsExpireAt;

  const StripeSubscription({
    required this.id,
    required this.status,
    required this.rawStatus,
    required this.plan,
    this.nextPlan,
    required this.inTrial,
    this.trialEnd,
    this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    this.creditsExpireAt,
  });

  bool get isActiveOrTrial =>
      status == StripeSubscriptionStatus.active ||
      status == StripeSubscriptionStatus.trialing;

  String get formattedCurrentPeriodEnd {
    if (currentPeriodEnd == null) return '';
    return DateFormat.yMMMd().format(currentPeriodEnd!.toLocal());
  }

  String get formattedTrialEnd {
    if (trialEnd == null) return '';
    return DateFormat.yMMMd().format(trialEnd!.toLocal());
  }

  String get formattedCreditsExpireAt {
    if (creditsExpireAt == null) return '';
    return DateFormat.yMMMd().format(creditsExpireAt!.toLocal());
  }

  factory StripeSubscription.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString() ?? '';
    final planMap = json['plan'] as Map<String, dynamic>? ?? {};
    final nextPlanMap = json['next_plan'] as Map<String, dynamic>?;

    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      try {
        return DateTime.parse(date.toString());
      } catch (_) {
        return null;
      }
    }

    return StripeSubscription(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: StripeSubscriptionStatus.fromString(rawStatus),
      rawStatus: rawStatus,
      plan: SubscriptionPlanSummary.fromJson(planMap),
      nextPlan: nextPlanMap != null
          ? SubscriptionPlanSummary.fromJson(nextPlanMap)
          : null,
      inTrial: json['in_trial'] as bool? ?? false,
      trialEnd: parseDate(json['trial_end']),
      currentPeriodEnd: parseDate(json['current_period_end']),
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      creditsExpireAt: parseDate(json['credits_expire_at']),
    );
  }
}

/// Credits balance returned in subscription response
class SubscriptionCredits {
  final int resume;
  final int interview;
  final int quiz;
  final int documentUpload;
  final int askScout;

  const SubscriptionCredits({
    this.resume = 0,
    this.interview = 0,
    this.quiz = 0,
    this.documentUpload = 0,
    this.askScout = 0,
  });

  factory SubscriptionCredits.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SubscriptionCredits();
    return SubscriptionCredits(
      resume: (json['resume'] as num?)?.toInt() ?? 0,
      interview: (json['interview'] as num?)?.toInt() ?? 0,
      quiz: (json['quiz'] as num?)?.toInt() ?? 0,
      documentUpload: (json['document_upload'] as num?)?.toInt() ?? 0,
      askScout: (json['ask_scout'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resume': resume,
      'interview': interview,
      'quiz': quiz,
      'document_upload': documentUpload,
      'ask_scout': askScout,
    };
  }
}

/// Payment transaction object from subscription payments list
class SubscriptionPayment {
  final int id;
  final String amount;
  final String currency;
  final String status;
  final String plan;
  final String reason;
  final DateTime? paidAt;
  final String? invoiceUrl;

  const SubscriptionPayment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.plan,
    required this.reason,
    this.paidAt,
    this.invoiceUrl,
  });

  String get formattedPaidAt {
    if (paidAt == null) return '';
    return DateFormat.yMMMd().format(paidAt!.toLocal());
  }

  String get formattedAmount => '\$$amount ${currency.toUpperCase()}';

  factory SubscriptionPayment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      try {
        return DateTime.parse(date.toString());
      } catch (_) {
        return null;
      }
    }

    return SubscriptionPayment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      amount: json['amount']?.toString() ?? '0.00',
      currency: json['currency']?.toString() ?? 'USD',
      status: json['status']?.toString() ?? '',
      plan: json['plan']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      paidAt: parseDate(json['paid_at']),
      invoiceUrl: json['invoice_url']?.toString(),
    );
  }
}

/// Unified response from GET /plan/subscription/, POST /verify/, PUT /update/, POST /cancel/
class SubscriptionStateResponse {
  final String status;
  final String message;
  final StripeSubscription? subscription;
  final SubscriptionCredits credits;
  final List<SubscriptionPayment> payments;
  final String? effective; // 'now' or 'next_renewal' (from update)

  const SubscriptionStateResponse({
    required this.status,
    required this.message,
    this.subscription,
    this.credits = const SubscriptionCredits(),
    this.payments = const [],
    this.effective,
  });

  bool get hasActiveSubscription =>
      subscription != null && subscription!.isActiveOrTrial;

  factory SubscriptionStateResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    final subMap = data['subscription'] as Map<String, dynamic>?;
    final credMap = data['credits'] as Map<String, dynamic>?;
    final rawPayments = data['payments'] as List<dynamic>? ?? [];

    final payments = rawPayments
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionPayment.fromJson)
        .toList();

    return SubscriptionStateResponse(
      status: json['status']?.toString() ?? 'success',
      message: json['message']?.toString() ?? '',
      subscription: subMap != null ? StripeSubscription.fromJson(subMap) : null,
      credits: SubscriptionCredits.fromJson(credMap),
      payments: payments,
      effective: data['effective']?.toString(),
    );
  }
}

/// Response from POST /plan/subscription/checkout/
class StripeCheckoutData {
  final String checkoutUrl;
  final String sessionId;
  final int planId;
  final bool hasTrial;
  final int trialDays;

  const StripeCheckoutData({
    required this.checkoutUrl,
    required this.sessionId,
    required this.planId,
    required this.hasTrial,
    required this.trialDays,
  });

  factory StripeCheckoutData.fromJson(Map<String, dynamic> json) {
    return StripeCheckoutData(
      checkoutUrl: json['checkout_url']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      planId: (json['plan_id'] as num?)?.toInt() ?? 0,
      hasTrial: json['has_trial'] as bool? ?? false,
      trialDays: (json['trial_days'] as num?)?.toInt() ?? 0,
    );
  }
}
