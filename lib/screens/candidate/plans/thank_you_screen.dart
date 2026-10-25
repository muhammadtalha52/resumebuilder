import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../../models/backend_plan_model.dart';
import '../../../providers/stripe_subscription_provider.dart';
import '../../../services/analytics_service.dart';

/// Post-Purchase Thank-You Funnel Screen.
///
/// Displays trial/subscription activation confirmation,
/// fires strictly-deduplicated analytics event,
/// and executes an automatic 5-second countdown redirect to Dashboard.
class ThankYouScreen extends ConsumerStatefulWidget {
  final BackendPlanModel? plan;
  final String? sessionId;
  final bool isTrial;

  const ThankYouScreen({
    super.key,
    this.plan,
    this.sessionId,
    this.isTrial = true,
  });

  @override
  ConsumerState<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends ConsumerState<ThankYouScreen> {
  int _secondsRemaining = 5;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _fireDeduplicatedAnalytics();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _fireDeduplicatedAnalytics() {
    final stripeState = ref.read(stripeSubscriptionProvider);
    final sub = stripeState.subscription;
    final planName = widget.plan?.name ?? sub?.plan.name ?? 'Subscription';
    final priceVal = double.tryParse(widget.plan?.price ?? sub?.plan.price ?? '0') ?? 0.0;
    final id = widget.sessionId ?? sub?.id.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    if (widget.isTrial) {
      // Fire trial_started event strictly once using session ID deduplication to Meta and GA4
      AnalyticsService.logTrialStartedStrictOnce(
        planName: planName,
        value: priceVal,
        currency: 'USD',
        sessionId: id,
      );
    } else {
      // Fire purchase event strictly once using transaction ID deduplication to Meta and GA4
      AnalyticsService.logPurchase(
        transactionId: id,
        value: priceVal,
        currency: 'USD',
        planName: planName,
        productId: widget.plan?.id.toString() ?? sub?.plan.id.toString(),
      );
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    _countdownTimer?.cancel();
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stripeState = ref.watch(stripeSubscriptionProvider);
    final sub = stripeState.subscription;
    final planName = widget.plan?.name ?? sub?.plan.name ?? 'Premium Plan';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _navigateToDashboard();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Animated Green Success Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 64,
                      color: Colors.green.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Heading
                Text(
                  widget.isTrial
                      ? 'Your Free Trial Has Started! 🎉'
                      : 'Your Subscription Is Active! 🎉',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  widget.isTrial
                      ? 'Welcome to unlimited AI intelligence. Enjoy 3 days of full access to refine your resumes and conquer interviews.'
                      : 'Thank you for upgrading! Your credits and AI features are now unlocked and ready to use.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),

                // Plan Details Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Selected Plan',
                        value: planName,
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      _buildDetailRow(
                        icon: Icons.verified_outlined,
                        label: 'Status',
                        value: widget.isTrial ? 'Active (3-Day Free Trial)' : 'Active Plan',
                        valueColor: Colors.green.shade700,
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      _buildDetailRow(
                        icon: Icons.event_repeat_rounded,
                        label: widget.isTrial ? 'First Charge' : 'Renewal',
                        value: widget.isTrial
                            ? 'Day 4 (Cancel anytime)'
                            : 'Renews automatically',
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 5-Second Countdown Indicator
                Text(
                  'Redirecting to your dashboard in $_secondsRemaining seconds...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Manual Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _navigateToDashboard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue to Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
