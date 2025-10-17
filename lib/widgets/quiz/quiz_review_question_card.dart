import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/quize_model.dart';
import 'quiz_option_tile.dart';

class QuizReviewQuestionCard extends StatelessWidget {
  final Items question;
  final int questionNumber;

  const QuizReviewQuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
  });

  @override
  Widget build(BuildContext context) {
    final options = question.getOptionsMap();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question number badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: question.isCorrect
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: question.isCorrect ? Colors.green : Colors.red.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                question.isCorrect ? Icons.check_circle : Icons.cancel,
                color: question.isCorrect ? Colors.green : Colors.red.shade400,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Question $questionNumber',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: question.isCorrect
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Question text
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Q.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  question.question ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Options (read-only)
        ...options.entries.map((entry) {
          final label = entry.key;
          final text = entry.value;
          final state = _getOptionState(label);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: QuizOptionTile(
              label: label,
              text: text,
              state: state,
              onTap: null, // Read-only, no interaction
            ),
          );
        }),
        // Answer summary
        if (!question.isCorrect) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red.shade600, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your answer: ${question.selectedLabel} • Correct answer: ${question.correctLabel}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  QuizOptionState _getOptionState(String label) {
    final isThisCorrect = label == question.correctLabel;
    final isThisSelected = label == question.selectedLabel;

    if (isThisSelected && isThisCorrect) {
      return QuizOptionState.correct;
    } else if (isThisSelected && !isThisCorrect) {
      return QuizOptionState.incorrect;
    } else if (!isThisSelected && isThisCorrect) {
      // Show the correct answer even if user didn't select it (for review purposes)
      return QuizOptionState.showCorrect;
    } else {
      return QuizOptionState.normal;
    }
  }
}
