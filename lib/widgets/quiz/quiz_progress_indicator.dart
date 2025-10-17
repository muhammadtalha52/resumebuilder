import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class QuizProgressIndicator extends StatelessWidget {
  final int totalQuestions;
  final int currentIndex;
  final List<bool> answeredStatus;

  const QuizProgressIndicator({
    super.key,
    required this.totalQuestions,
    required this.currentIndex,
    required this.answeredStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (currentIndex + 1) / totalQuestions,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Question counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${currentIndex + 1} of $totalQuestions',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_getAnsweredCount()} answered',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _getAnsweredCount() {
    return answeredStatus.where((answered) => answered).length;
  }
}
