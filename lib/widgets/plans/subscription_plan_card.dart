import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/backend_plan_model.dart';
import '../../models/stripe_subscription_model.dart';

class SubscriptionPlanCard extends StatelessWidget {
  final BackendPlanModel plan;
  final StripeSubscription? currentSubscription;
  final VoidCallback onSelect;
  final bool isLoading;
  final String? customButtonText;
  final String? customPrice;
  final bool isOneTime;

  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    this.currentSubscription,
    required this.onSelect,
    this.isLoading = false,
    this.customButtonText,
    this.customPrice,
    this.isOneTime = false,
  });

  bool get isCurrentPlan =>
      currentSubscription != null &&
      currentSubscription!.plan.id == plan.id &&
      currentSubscription!.isActiveOrTrial;

  bool get isNextPendingPlan =>
      currentSubscription != null &&
      currentSubscription!.nextPlan?.id == plan.id;

  List<String> get cardFeatures {
    final list = <String>[];
    final intervalStr = (isOneTime || !plan.isSubscription || plan.billingInterval == null || plan.billingInterval!.isEmpty)
        ? ''
        : (plan.isWeekly ? ' a week' : ' a month');

    // Candidate features
    if (plan.resumeCount > 0) {
      list.add('${plan.resumeCount} Resumes$intervalStr');
    }
    if (plan.interviewCount > 0) {
      list.add('${plan.interviewCount} Live Sessions$intervalStr');
    }
    if (plan.askScoutCount > 0) {
      list.add('${plan.askScoutCount} Ask Scout questions$intervalStr');
    }

    // Student features
    if (plan.quizCount > 0) {
      list.add(
        '${plan.quizCount} Guided Study Sessions (with Custom Quiz)$intervalStr',
      );
    }
    if (plan.documentUploadCount > 0) {
      list.add('${plan.documentUploadCount} Document uploads$intervalStr');
    }

    // Trial or student extras
    if (plan.quizCount > 0 || plan.documentUploadCount > 0) {
      list.add('Quiz history & progress tracking included');
    } else if (!isOneTime && plan.isSubscription && plan.hasTrial) {
      list.add('${plan.trialDays}-day free trial included');
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSub = currentSubscription?.isActiveOrTrial ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: plan.isRecommended
                ? AppColors.primary.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: plan.isRecommended ? 22 : 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isCurrentPlan
              ? AppColors.success
              : (plan.isRecommended
                  ? AppColors.primary
                  : AppColors.border),
          width: isCurrentPlan || plan.isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Icon + Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/icons/fox-mascot.png',
                height: 42,
                errorBuilder: (_, _, _) => Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
              Row(
                children: [
                  if (isCurrentPlan)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Current Plan',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isNextPendingPlan)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.info),
                      ),
                      child: const Text(
                        'Starts Next Renewal',
                        style: TextStyle(
                          color: AppColors.info,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (plan.isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradientHorizontal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Best Value',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Plan Name
          Text(
            plan.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Price & Billing interval
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                customPrice ?? '\$${plan.price.replaceAll('\$', '')}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              if (!isOneTime && !Platform.isIOS && plan.isSubscription && plan.billingInterval != null && plan.billingInterval!.isNotEmpty)
                Text(
                  'a ${plan.formattedBillingInterval}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                const Text(
                  'one-time pack',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),

          // Trial callout (only for subscriptions with trial, NEVER for one-time packs)
          if (!isOneTime && !Platform.isIOS && plan.isSubscription && plan.hasTrial && !hasActiveSub) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${plan.trialDays} days free trial included',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentDark,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Features List
          ...cardFeatures.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: _buildActionButton(hasActiveSub),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool hasActiveSub) {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (isCurrentPlan) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check, size: 16, color: AppColors.success),
        label: const Text(
          'Your Current Plan',
          style: TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.success),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    String buttonText;
    if (customButtonText != null && customButtonText!.isNotEmpty) {
      buttonText = customButtonText!;
    } else if (Platform.isIOS) {
      buttonText = 'Get Plan';
    } else if (hasActiveSub) {
      buttonText = isNextPendingPlan ? 'Change Plan' : 'Switch to this Plan';
    } else if (plan.hasTrial) {
      buttonText = 'Start 3-Day Free Trial';
    } else {
      buttonText = 'Subscribe Now';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradientHorizontal,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onSelect,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
