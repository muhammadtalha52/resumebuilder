import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/stripe_subscription_model.dart';

class ActiveSubscriptionCard extends StatelessWidget {
  final StripeSubscription subscription;
  final List<SubscriptionPayment> payments;
  final VoidCallback onCancelOrUndo;
  final Function(String) onOpenInvoice;
  final bool isCanceling;
  final EdgeInsetsGeometry? margin;

  const ActiveSubscriptionCard({
    super.key,
    required this.subscription,
    this.payments = const [],
    required this.onCancelOrUndo,
    required this.onOpenInvoice,
    this.isCanceling = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isTrial = subscription.inTrial;
    final isCancelingAtPeriodEnd = subscription.cancelAtPeriodEnd;
    final nextPlan = subscription.nextPlan;

    Color badgeColor;
    String badgeText;

    if (isCancelingAtPeriodEnd) {
      badgeColor = AppColors.warning;
      badgeText = 'Canceling at Period End';
    } else if (isTrial) {
      badgeColor = AppColors.accent;
      final days = subscription.plan.trialDays > 0 ? subscription.plan.trialDays : 7;
      badgeText = '$days-Day Free Trial';
    } else if (subscription.status == StripeSubscriptionStatus.active) {
      badgeColor = AppColors.success;
      badgeText = 'Active Plan';
    } else if (subscription.status == StripeSubscriptionStatus.pastDue) {
      badgeColor = AppColors.error;
      badgeText = 'Payment Past Due';
    } else {
      badgeColor = AppColors.grey;
      badgeText = subscription.status.displayName;
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subscription.plan.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subscription.plan.formattedPrice,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Trial End or Renewal Date
          if (isTrial && subscription.trialEnd != null) ...[
            _buildInfoRow(
              icon: Icons.timer_outlined,
              label: 'Trial Ends:',
              value: subscription.formattedTrialEnd,
              highlight: true,
            ),
            const SizedBox(height: 6),
          ],

          if (subscription.currentPeriodEnd != null) ...[
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              label: isCancelingAtPeriodEnd ? 'Access Ends:' : 'Renews On:',
              value: subscription.formattedCurrentPeriodEnd,
            ),
            const SizedBox(height: 6),
          ],

          if (subscription.creditsExpireAt != null) ...[
            _buildInfoRow(
              icon: Icons.hourglass_bottom_rounded,
              label: 'Credits Expire:',
              value: subscription.formattedCreditsExpireAt,
            ),
            const SizedBox(height: 6),
          ],

          // In-trial cancellation notice
          if (isTrial && isCancelingAtPeriodEnd && subscription.trialEnd != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your trial ends on ${subscription.formattedTrialEnd}. You won\'t be charged.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Next Plan downgrade alert
          if (nextPlan != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 18, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Downgrade to ${nextPlan.name} (${nextPlan.formattedPrice}) takes effect on next renewal (${subscription.formattedCurrentPeriodEnd}).',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Actions Row: Cancel/Undo Cancel and View Payments
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isCanceling ? null : onCancelOrUndo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isCancelingAtPeriodEnd
                        ? AppColors.primary
                        : AppColors.error,
                    side: BorderSide(
                      color: isCancelingAtPeriodEnd
                          ? AppColors.primary
                          : AppColors.error.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isCanceling
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isCancelingAtPeriodEnd
                              ? (isTrial ? 'Keep My Trial' : 'Keep Subscription')
                              : 'Cancel Subscription',
                          style: const TextStyle(fontSize: 13),
                        ),
                ),
              ),
              if (payments.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showPaymentHistorySheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Invoices',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: highlight ? AppColors.accent : AppColors.textLight,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: highlight ? AppColors.accentDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showPaymentHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Billing Invoices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No invoice history found.'),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: payments.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final p = payments[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          p.plan.isNotEmpty ? p.plan : 'Subscription Cycle',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${p.formattedPaidAt} • ${p.status}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.formattedAmount,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (p.invoiceUrl != null &&
                                p.invoiceUrl!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.receipt_long_outlined,
                                  color: AppColors.primary,
                                ),
                                tooltip: 'View Invoice',
                                onPressed: () {
                                  onOpenInvoice(p.invoiceUrl!);
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
