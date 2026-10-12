import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/backend_plan_model.dart';
import '../../models/stripe_subscription_model.dart';

class SubscriptionDialogs {
  /// Shows confirmation dialog for switching subscription plans (upgrade / downgrade)
  static Future<bool?> showPlanChangeDialog({
    required BuildContext context,
    required BackendPlanModel targetPlan,
    required StripeSubscription currentSubscription,
  }) {
    final currentPrice =
        double.tryParse(currentSubscription.plan.price.replaceAll('\$', '')) ??
            0.0;
    final targetPrice =
        double.tryParse(targetPlan.price.replaceAll('\$', '')) ?? 0.0;
    final isCurrentWeekly = currentSubscription.plan.isWeekly;
    final isTargetWeekly = targetPlan.isWeekly;

    // Upgrades: dearer plan, or change between weekly and monthly
    final isUpgrade = (targetPrice > currentPrice) ||
        (isCurrentWeekly != isTargetWeekly) ||
        currentSubscription.inTrial;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUpgrade ? Icons.arrow_upward : Icons.arrow_downward,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isUpgrade
                      ? 'Upgrade to ${targetPlan.name}'
                      : 'Downgrade to ${targetPlan.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price: ${targetPlan.formattedPrice}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              if (currentSubscription.inTrial) ...[
                _buildBullet(
                  'Change takes effect now. In a trial, changes are allowed and you keep your trial credits.',
                ),
              ] else if (isUpgrade) ...[
                _buildBullet(
                  'Starts at once today. The difference is charged immediately.',
                ),
                _buildBullet(
                  'Your new plan\'s full credits arrive immediately.',
                ),
                _buildBullet(
                  'Unused credits from your previous plan expire.',
                ),
              ] else ...[
                _buildBullet(
                  'Starts at your next renewal (${currentSubscription.formattedCurrentPeriodEnd}).',
                ),
                _buildBullet(
                  'Nothing changes until renewal; your current plan and credits stay intact.',
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(isUpgrade ? 'Confirm Upgrade' : 'Confirm Change'),
            ),
          ],
        );
      },
    );
  }

  /// Shows confirmation dialog for cancellation or undoing cancellation
  static Future<bool?> showCancelConfirmationDialog({
    required BuildContext context,
    required StripeSubscription subscription,
  }) {
    final isCancelingAtPeriodEnd = subscription.cancelAtPeriodEnd;
    final inTrial = subscription.inTrial;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        if (isCancelingAtPeriodEnd) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Undo Cancellation?'),
            content: const Text(
              'Your subscription will continue renewing as scheduled at the end of the current billing cycle.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep Canceled'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Resume Subscription'),
              ),
            ],
          );
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            inTrial ? 'Cancel Free Trial?' : 'Cancel Subscription?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (inTrial) ...[
                _buildBullet(
                  'In a trial, cancellation ends at once and trial credits are removed.',
                ),
                _buildBullet(
                  'Cancelling and subscribing again does NOT give a second trial.',
                ),
              ] else ...[
                _buildBullet(
                  'Your plan and credits stay active until the end of the paid period (${subscription.formattedCurrentPeriodEnd}).',
                ),
                _buildBullet(
                  'You will not be billed again after that date.',
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Plan', style: TextStyle(color: AppColors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(inTrial ? 'End Trial Now' : 'Confirm Cancel'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
