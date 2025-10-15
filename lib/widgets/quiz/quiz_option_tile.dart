import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

enum QuizOptionState {
  normal, // Not selected, not answered yet
  selected, // Selected but not checked yet
  correct, // Answered and this is the correct answer
  incorrect, // Selected and answered, but this is the wrong answer
  showCorrect, // Not selected, but showing the correct answer after wrong selection
}

class QuizOptionTile extends StatelessWidget {
  final String label; // A, B, C, or D
  final String text;
  final QuizOptionState state;
  final VoidCallback? onTap;

  const QuizOptionTile({
    super.key,
    required this.label,
    required this.text,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          state == QuizOptionState.normal || state == QuizOptionState.selected
          ? onTap
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getBorderColor(), width: 2),
          boxShadow: state == QuizOptionState.selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Label circle (A, B, C, D)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getLabelBackgroundColor(),
                shape: BoxShape.circle,
                border: Border.all(color: _getLabelBorderColor(), width: 1.5),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _getLabelTextColor(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Option text
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(),
                  height: 1.4,
                ),
              ),
            ),
            // Trailing icon (checkmark or X)
            if (state == QuizOptionState.correct ||
                state == QuizOptionState.showCorrect)
              const Icon(Icons.check_circle, color: Colors.green, size: 24)
            else if (state == QuizOptionState.incorrect)
              const Icon(Icons.cancel, color: Colors.red, size: 24),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (state) {
      case QuizOptionState.normal:
        return AppColors.white;
      case QuizOptionState.selected:
        return AppColors.primary.withValues(alpha: 0.05);
      case QuizOptionState.correct:
        return Colors.green.withValues(alpha: 0.1);
      case QuizOptionState.incorrect:
        return Colors.red.withValues(alpha: 0.1);
      case QuizOptionState.showCorrect:
        return Colors.green.withValues(alpha: 0.05);
    }
  }

  Color _getBorderColor() {
    switch (state) {
      case QuizOptionState.normal:
        return AppColors.textSecondary.withValues(alpha: 0.3);
      case QuizOptionState.selected:
        return AppColors.primary;
      case QuizOptionState.correct:
        return Colors.green;
      case QuizOptionState.incorrect:
        return Colors.red;
      case QuizOptionState.showCorrect:
        return Colors.green;
    }
  }

  Color _getLabelBackgroundColor() {
    switch (state) {
      case QuizOptionState.normal:
        return AppColors.white;
      case QuizOptionState.selected:
        return AppColors.primary;
      case QuizOptionState.correct:
        return Colors.green;
      case QuizOptionState.incorrect:
        return Colors.red;
      case QuizOptionState.showCorrect:
        return Colors.green.withValues(alpha: 0.1);
    }
  }

  Color _getLabelBorderColor() {
    switch (state) {
      case QuizOptionState.normal:
        return AppColors.textSecondary.withValues(alpha: 0.5);
      case QuizOptionState.selected:
        return AppColors.primary;
      case QuizOptionState.correct:
        return Colors.green;
      case QuizOptionState.incorrect:
        return Colors.red;
      case QuizOptionState.showCorrect:
        return Colors.green;
    }
  }

  Color _getLabelTextColor() {
    switch (state) {
      case QuizOptionState.normal:
        return AppColors.textPrimary;
      case QuizOptionState.selected:
        return AppColors.white;
      case QuizOptionState.correct:
        return AppColors.white;
      case QuizOptionState.incorrect:
        return AppColors.white;
      case QuizOptionState.showCorrect:
        return Colors.green;
    }
  }

  Color _getTextColor() {
    switch (state) {
      case QuizOptionState.normal:
      case QuizOptionState.selected:
        return AppColors.textPrimary;
      case QuizOptionState.correct:
        return Colors.green.shade900;
      case QuizOptionState.incorrect:
        return Colors.red.shade900;
      case QuizOptionState.showCorrect:
        return Colors.green.shade900;
    }
  }
}
