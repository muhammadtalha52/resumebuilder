import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/quize_model.dart';
import '../../providers/quiz_provider.dart';
import '../common/custom_button.dart';
import 'quiz_option_tile.dart';

class QuizQuestionCard extends ConsumerWidget {
  final Items question;

  const QuizQuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = question.getOptionsMap();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 20),
        // Options
        ...options.entries.map((entry) {
          final label = entry.key;
          final text = entry.value;

          // Determine option state
          final state = _getOptionState(label);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: QuizOptionTile(
              label: label,
              text: text,
              state: state,
              onTap: question.isAnswered
                  ? null
                  : () {
                      ref.read(quizProvider.notifier).selectAnswer(label);
                    },
            ),
          );
        }),
        const SizedBox(height: 20),
        // Action button
        if (!question.isAnswered)
          _buildCheckAnswerButton(context, ref)
        else
          _buildAnswerFeedback(),
      ],
    );
  }

  QuizOptionState _getOptionState(String label) {
    // If not answered yet
    if (!question.isAnswered) {
      // Show selected state if this option is selected
      return question.selectedLabel == label
          ? QuizOptionState.selected
          : QuizOptionState.normal;
    }

    // If answered, only highlight the user's selected answer
    final isThisCorrect = label == question.correctLabel;
    final isThisSelected = label == question.selectedLabel;

    if (isThisSelected && isThisCorrect) {
      return QuizOptionState.correct;
    } else if (isThisSelected && !isThisCorrect) {
      return QuizOptionState.incorrect;
    } else {
      // Don't highlight the correct answer if user didn't select it
      return QuizOptionState.normal;
    }
  }

  Widget _buildCheckAnswerButton(BuildContext context, WidgetRef ref) {
    final hasSelected = question.selectedLabel != null;

    return CustomButton(
      text: hasSelected ? 'Check Answer' : 'Select an option',
      onPressed: hasSelected
          ? () {
              ref.read(quizProvider.notifier).checkAnswer();
            }
          : null,
      width: double.infinity,
      useGradient: true,
    );
  }

  Widget _buildAnswerFeedback() {
    final isCorrect = question.isCorrect;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.red,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? Colors.green : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCorrect
                  ? 'Correct! Well done!'
                  : 'Incorrect. Correct answer is ${question.correctLabel}.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isCorrect ? Colors.green.shade900 : Colors.red.shade900,
              ),
            ),
          ),
          if (isCorrect) ...[
            const SizedBox(width: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 1.15),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              onEnd: () {},
              child: Image.asset(
                'assets/icons/fox-mascot.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
