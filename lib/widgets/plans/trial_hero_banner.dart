import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Web-aligned trial banner displayed above the subscription plans carousel.
/// Shows the role-specific free trial credits and a "Start At $0 Today" CTA.
class TrialHeroBanner extends StatelessWidget {
  final bool isStudent;
  final int trialDays;
  final VoidCallback onStartTrial;
  final bool isLoading;

  const TrialHeroBanner({
    super.key,
    required this.isStudent,
    this.trialDays = 7,
    required this.onStartTrial,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final trialSummary = isStudent
        ? 'Includes 5 guided study quizzes and 10 document uploads. Cancel anytime before day ${trialDays + 1} and you won\'t be charged.'
        : 'Includes 3 tailored resumes and 2 live interview sessions. Cancel anytime before day ${trialDays + 1} and you won\'t be charged.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start your $trialDays-day free trial.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trialSummary,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradientHorizontal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : onStartTrial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Start At \$0 Today',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.white,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

