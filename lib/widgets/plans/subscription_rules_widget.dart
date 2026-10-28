import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class SubscriptionRulesWidget extends StatefulWidget {
  final bool isStudent;

  const SubscriptionRulesWidget({super.key, this.isStudent = false});

  @override
  State<SubscriptionRulesWidget> createState() =>
      _SubscriptionRulesWidgetState();
}

class _SubscriptionRulesWidgetState extends State<SubscriptionRulesWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Subscription Rules & How It Works',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded) ...[
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRuleItem(
                      icon: Icons.refresh_rounded,
                      title: 'Credit Delivery & Expiration',
                      description:
                          'A full set of credits arrives every week (weekly plans) or month. Unused credits expire at the end of the period and do not carry over.',
                    ),
                    const SizedBox(height: 12),
                    _buildRuleItem(
                      icon: Icons.star_border_rounded,
                      title: '7-Day Free Trial',
                      description:
                          'Job seeker and student plans include 7 days free with a card on file. The first charge occurs on day 8. Job seekers get 3 tailored resumes and 2 live sessions; students get 5 guided study sessions and 10 document uploads. Cancelling and subscribing again does not give a second trial.',
                    ),
                    const SizedBox(height: 12),
                    _buildRuleItem(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Upgrades & Downgrades',
                      description:
                          'Upgrade: Starts at once, the difference is charged today, and the new plan\'s full credits arrive. Downgrade: Starts at the next renewal.',
                    ),
                    const SizedBox(height: 12),
                    _buildRuleItem(
                      icon: Icons.cancel_outlined,
                      title: 'Cancel Any Time',
                      description:
                          'Cancelling during a trial stops the day 8 charge, and your trial credits stay usable until the trial ends. After a trial, the plan and credits remain active until the end of the paid period.',
                    ),

                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
