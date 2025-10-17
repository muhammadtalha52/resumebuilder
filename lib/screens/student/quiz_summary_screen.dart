import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/quiz_history_provider.dart';
import '../../services/quiz_history_service.dart';
import '../../widgets/common/custom_app_bar.dart';

class QuizSummaryScreen extends ConsumerStatefulWidget {
  final String lectureName;

  const QuizSummaryScreen({super.key, required this.lectureName});

  @override
  ConsumerState<QuizSummaryScreen> createState() => _QuizSummaryScreenState();
}

class _QuizSummaryScreenState extends ConsumerState<QuizSummaryScreen> {
  bool _savedToHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveQuizToHistory();
    });
  }

  Future<void> _saveQuizToHistory() async {
    if (_savedToHistory) return;

    final quizState = ref.read(quizProvider);
    final summary = ref.read(quizProvider.notifier).getSummary();

    if (quizState.quiz != null) {
      final service = ref.read(quizHistoryServiceProvider);
      await service.saveQuiz(
        lectureName: widget.lectureName,
        quiz: quizState.quiz!,
        correctAnswers: summary.correctAnswers,
        totalQuestions: summary.totalQuestions,
      );
      // Refresh history
      ref.read(quizHistoryProvider.notifier).loadHistory();
      _savedToHistory = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final summary = ref.read(quizProvider.notifier).getSummary();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: BackNavigationAppBar(
        title: 'Quiz Results',
        onBackPressed: () {
          ref.read(quizProvider.notifier).reset();
          Navigator.pop(context);
        },
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
            padding: const EdgeInsets.all(32),
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
              children: [
                // Fox mascot image
                Image.asset(_getResultImage(summary.percentage), height: 100),
                const SizedBox(height: 24),
                // Encouraging title
                Text(
                  _getEncouragingTitle(summary.percentage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                // Encouraging message
                Text(
                  _getEncouragingMessage(summary.percentage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.check_circle,
                        color: Colors.green,
                        label: 'Correct',
                        value:
                            '${summary.correctAnswers}/${summary.totalQuestions}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.cancel,
                        color: Colors.red.shade400,
                        label: 'Incorrect',
                        value:
                            '${summary.incorrectAnswers}/${summary.totalQuestions}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Action buttons
                _buildActionButton(
                  context: context,
                  ref: ref,
                  label: 'Review Answers',
                  icon: Icons.rate_review,
                  isPrimary: false,
                  onTap: () {
                    final quiz = ref.read(quizProvider).quiz;
                    if (quiz != null) {
                      context.push(
                        '/quiz/review?lectureName=${Uri.encodeComponent(widget.lectureName)}',
                        extra: quiz,
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context: context,
                  label: 'Done',
                  icon: Icons.home,
                  isPrimary: true,
                  onTap: () {
                    ref.read(quizProvider.notifier).reset();
                    // Go back to documents/lectures screen
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    WidgetRef? ref,
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.primary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? AppColors.white : AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isPrimary ? AppColors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getResultImage(double percentage) {
    if (percentage >= 90) {
      return 'assets/icons/interview-fox.png'; // Use trophy when you have one
    } else if (percentage >= 70) {
      return 'assets/icons/interview-fox.png'; // Use medal when you have one
    } else {
      return 'assets/icons/interview-fox.png'; // Use encourage image
    }
  }

  String _getEncouragingTitle(double percentage) {
    if (percentage >= 90) {
      return "You're a Quiz Master! 🌟";
    } else if (percentage >= 80) {
      return 'Almost Perfect! 🎯';
    } else if (percentage >= 70) {
      return 'Great Progress! 💪';
    } else if (percentage >= 60) {
      return 'Keep Going! 📚';
    } else if (percentage >= 50) {
      return 'Nice Try! 🔥';
    } else {
      return 'Keep Learning! 🚀';
    }
  }

  String _getEncouragingMessage(double percentage) {
    if (percentage >= 90) {
      return 'Excellent performance. You’ve demonstrated strong understanding of the material.';
    } else if (percentage >= 80) {
      return 'Great work. You’re showing solid progress and a clear grasp of the concepts.';
    } else if (percentage >= 70) {
      return 'Good effort. Review the areas you missed to strengthen your understanding.';
    } else if (percentage >= 60) {
      return 'You’re improving. Revisit key topics to build more confidence.';
    } else if (percentage >= 50) {
      return 'Keep going. Focused revision will help you perform better next time.';
    } else {
      return 'Don’t be discouraged. Consistent practice and review will lead to steady improvement.';
    }
  }
}
