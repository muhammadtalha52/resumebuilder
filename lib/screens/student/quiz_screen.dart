import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/quize_model.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/quiz/quiz_question_card.dart';
import '../../widgets/quiz/quiz_progress_indicator.dart';
import '../../widgets/dialogs/confirmation_dialog.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final QuizModel quiz;
  final String lectureName;

  const QuizScreen({super.key, required this.quiz, required this.lectureName});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  @override
  void initState() {
    super.initState();
    // Load quiz data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizProvider.notifier).loadQuiz(widget.quiz);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final currentQuestion = quizState.getCurrentQuestion();

    if (currentQuestion == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: BackNavigationAppBar(
          title: 'Quiz',
          onBackPressed: () => Navigator.pop(context),
        ),
        body: const Center(child: Text('No questions available')),
      );
    }

    final totalQuestions = quizState.getTotalQuestions();
    final answeredStatus =
        quizState.quiz?.items?.map((item) => item.isAnswered).toList() ?? [];

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: BackNavigationAppBar(
        title: widget.lectureName,
        onBackPressed: () => _handleBackPress(context),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress indicator
                QuizProgressIndicator(
                  totalQuestions: totalQuestions,
                  currentIndex: quizState.currentQuestionIndex,
                  answeredStatus: answeredStatus,
                ),
                const SizedBox(height: 24),
                // Question card
                QuizQuestionCard(question: currentQuestion),
                const SizedBox(height: 24),
                // Navigation buttons
                Row(
                  children: [
                    // Previous button
                    if (quizState.canGoPrevious())
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref.read(quizProvider.notifier).previousQuestion();
                          },
                          icon: const Icon(Icons.arrow_back, size: 20),
                          label: const Text('Previous'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (quizState.canGoPrevious()) const SizedBox(width: 12),
                    // Next/Finish button
                    Expanded(
                      flex: quizState.canGoPrevious() ? 1 : 2,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: currentQuestion.isAnswered
                              ? AppColors.primaryGradientHorizontal
                              : null,
                          color: currentQuestion.isAnswered
                              ? null
                              : AppColors.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: currentQuestion.isAnswered
                                ? () {
                                    if (quizState.isLastQuestion()) {
                                      _navigateToSummary(context);
                                    } else {
                                      ref
                                          .read(quizProvider.notifier)
                                          .nextQuestion();
                                    }
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  quizState.isLastQuestion()
                                      ? Icons.check_circle
                                      : Icons.arrow_forward,
                                  size: 20,
                                  color: currentQuestion.isAnswered
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  quizState.isLastQuestion()
                                      ? 'Finish Quiz'
                                      : 'Next',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: currentQuestion.isAnswered
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleBackPress(BuildContext context) async {
    final quizState = ref.read(quizProvider);

    // If quiz is not completed, show confirmation dialog
    if (!quizState.isQuizCompleted()) {
      final confirmed = await showConfirmationDialog(
        context: context,
        title: 'Exit Quiz?',
        subtitle:
            'Your progress will be lost if you exit now. Are you sure you want to leave?',
        icon: Icons.exit_to_app,
        iconBackgroundColor: AppColors.error,
        confirmText: 'Exit',
        cancelText: 'Cancel',
        confirmButtonColor: AppColors.error,
        confirmTextColor: Colors.white,
      );

      if (confirmed == true && context.mounted) {
        ref.read(quizProvider.notifier).reset();
        Navigator.pop(context);
      }
    } else {
      ref.read(quizProvider.notifier).reset();
      Navigator.pop(context);
    }
  }

  void _navigateToSummary(BuildContext context) {
    context.pushReplacement(
      '/quiz/summary?lectureName=${Uri.encodeComponent(widget.lectureName)}',
    );
  }
}
