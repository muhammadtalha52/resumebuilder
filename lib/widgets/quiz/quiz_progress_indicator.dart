import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class QuizProgressIndicator extends StatelessWidget {
  final int totalQuestions;
  final int currentIndex;
  final List<bool>
  answeredStatus; // List indicating which questions are answered

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
        const SizedBox(height: 16),
        // Question dots
        _buildQuestionDots(),
      ],
    );
  }

  Widget _buildQuestionDots() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(totalQuestions, (index) {
        final isCurrent = index == currentIndex;
        final isAnswered =
            index < answeredStatus.length && answeredStatus[index];

        return GestureDetector(
          onTap: () {
            // This will be handled by the parent screen
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getDotColor(isCurrent, isAnswered),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getDotBorderColor(isCurrent, isAnswered),
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: _getDotTextColor(isCurrent, isAnswered),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _getDotColor(bool isCurrent, bool isAnswered) {
    if (isCurrent) {
      return AppColors.primary;
    } else if (isAnswered) {
      return AppColors.primary.withValues(alpha: 0.2);
    } else {
      return AppColors.white;
    }
  }

  Color _getDotBorderColor(bool isCurrent, bool isAnswered) {
    if (isCurrent) {
      return AppColors.primary;
    } else if (isAnswered) {
      return AppColors.primary.withValues(alpha: 0.5);
    } else {
      return AppColors.textSecondary.withValues(alpha: 0.3);
    }
  }

  Color _getDotTextColor(bool isCurrent, bool isAnswered) {
    if (isCurrent) {
      return AppColors.white;
    } else if (isAnswered) {
      return AppColors.primary;
    } else {
      return AppColors.textSecondary;
    }
  }

  int _getAnsweredCount() {
    return answeredStatus.where((answered) => answered).length;
  }
}
