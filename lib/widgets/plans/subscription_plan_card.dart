import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/backend_plan_model.dart';
import '../../models/stripe_subscription_model.dart';
import '../../providers/iap_provider.dart';
import '../../utils/url_launcher_utils.dart';

class SubscriptionPlanCard extends ConsumerWidget {
  final BackendPlanModel plan;
  final StripeSubscription? currentSubscription;
  final VoidCallback onSelect;
  final bool isLoading;
  final String? customButtonText;
  final String? customPrice;
  final bool isOneTime;
  final VoidCallback? onRestorePurchases;

  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    this.currentSubscription,
    required this.onSelect,
    this.isLoading = false,
    this.customButtonText,
    this.customPrice,
    this.isOneTime = false,
    this.onRestorePurchases,
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
    final intervalStr = isOneTime
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
    }
    if (!isOneTime && plan.hasTrial) {
      list.add('${plan.trialDays}-day free trial included');
    }

    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveSub = currentSubscription?.isActiveOrTrial ?? false;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: (screenHeight * 0.006).clamp(4.0, 8.0),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.045,
        vertical: (screenHeight * 0.014).clamp(10.0, 15.0),
      ),
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
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
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
                  height: 38,
                  errorBuilder: (_, _, _) => Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 22,
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
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.success),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 13, color: AppColors.success),
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
                          vertical: 5,
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
                          horizontal: 10,
                          vertical: 5,
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
                    if (isOneTime && !Platform.isIOS) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF01875F).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF01875F).withValues(alpha: 0.35)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shop, size: 11, color: Color(0xFF01875F)),
                            SizedBox(width: 3),
                            Text(
                              'Play Store',
                              style: TextStyle(
                                color: Color(0xFF01875F),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

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

            // Price clarity line (Apple Guideline 3.1.2(c))
            if (!isOneTime && plan.hasTrial) ...[
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                  children: [
                    TextSpan(
                      text: '${plan.trialDays} days free trial, then ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '\$${plan.price.replaceAll('\$', '')}/${plan.isWeekly ? 'week' : 'month'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECE5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${plan.trialDays}-Day Free Trial',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE06D53),
                  ),
                ),
              ),
            ] else ...[
              // Price & Billing interval (non-trial)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    customPrice ?? '\$${plan.price.replaceAll('\$', '')}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOneTime
                        ? 'one-time pack'
                        : (plan.isWeekly ? 'per week' : 'per month'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),

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

            const SizedBox(height: 10),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: _buildActionButton(hasActiveSub),
            ),
            const SizedBox(height: 10),

            // Billing Disclosure (Apple Guideline 3.1.2(c))
            _buildBillingDisclosure(hasActiveSub),
            const SizedBox(height: 8),

            // Restore Purchases link
            Center(
              child: GestureDetector(
                onTap: () {
                  if (onRestorePurchases != null) {
                    onRestorePurchases!();
                  } else {
                    ref.read(iapProvider.notifier).restorePurchases();
                  }
                },
                child: const Text(
                  'Restore Purchases',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Terms of Use (EULA) | Privacy Policy links (Apple Guideline 3.1.2(c))
            _buildLegalLinks(),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            if (Platform.isIOS) {
              UrlLauncherUtils.launchExternalUrl(
                'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
              );
            } else {
              UrlLauncherUtils.launchTermsOfUse();
            }
          },
          child: const Text(
            'Terms of Use (EULA)',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '|',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            UrlLauncherUtils.launchPrivacyPolicy();
          },
          child: const Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillingDisclosure(bool hasActiveSub) {
    if (isOneTime) return const SizedBox.shrink();

    final cleanPrice = plan.price.replaceAll('\$', '');
    final priceStr = '\$$cleanPrice';
    final interval = plan.isWeekly ? 'week' : 'month';
    final renewFreq = plan.isWeekly ? 'weekly' : 'monthly';
    final storeName = Platform.isIOS ? 'Apple ID' : 'Google Play';
    final cancelPath = Platform.isIOS
        ? 'Settings > Apple ID > Subscriptions'
        : 'Google Play Store > Subscriptions';

    String disclosure;
    if (plan.hasTrial) {
      disclosure =
          'Billing begins automatically after the ${plan.trialDays}-day free trial '
          'at $priceStr/$interval unless cancelled. '
          'Subscription auto-renews $renewFreq until cancelled. '
          'Payment will be charged to your $storeName account. '
          'Cancel anytime (at least 24 hours before the period ends) '
          'in $cancelPath.';
    } else {
      disclosure =
          '$priceStr/$interval. Subscription auto-renews $renewFreq until '
          'cancelled. Payment will be charged to your $storeName account. '
          'Cancel anytime (at least 24 hours before the period ends) '
          'in $cancelPath.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        disclosure,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10.5,
          height: 1.4,
          color: Colors.grey.shade600,
        ),
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
    } else if (hasActiveSub) {
      buttonText = isNextPendingPlan ? 'Change Plan' : 'Switch to this Plan';
    } else if (plan.hasTrial) {
      buttonText = 'Start ${plan.trialDays}-Day Free Trial';
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
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
