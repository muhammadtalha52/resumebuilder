import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/quize_model.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/quiz/quiz_review_question_card.dart';

class QuizReviewScreen extends ConsumerWidget {
  final QuizModel quiz;
  final String lectureName;

  const QuizReviewScreen({
    super.key,
    required this.quiz,
    required this.lectureName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = quiz.items ?? [];
    final correctCount = questions.where((q) => q.isCorrect).length;
    final totalCount = questions.length;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: BackNavigationAppBar(
        title: 'Review Answers',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/icons/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with score summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.quiz,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lectureName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Score: $correctCount/$totalCount correct',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // All questions
                ...List.generate(questions.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: QuizReviewQuestionCard(
                      question: questions[index],
                      questionNumber: index + 1,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
