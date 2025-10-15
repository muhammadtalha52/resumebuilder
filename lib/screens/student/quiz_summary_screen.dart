import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/common/custom_app_bar.dart';

class QuizSummaryScreen extends ConsumerWidget {
  final String lectureName;

  const QuizSummaryScreen({super.key, required this.lectureName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: Column(
            children: [
              // Results card
              Container(
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
                    // Trophy/Medal image
                    Image.asset(
                      _getResultImage(summary.percentage),
                      height: 120,
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      _getResultTitle(summary.percentage),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      lectureName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Score circle
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getGradeColor(summary.grade),
                          width: 8,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${summary.percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: _getGradeColor(summary.grade),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Grade ${summary.grade}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _getGradeColor(summary.grade),
                            ),
                          ),
                        ],
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
                            value: summary.correctAnswers.toString(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.cancel,
                            color: Colors.red,
                            label: 'Incorrect',
                            value: summary.incorrectAnswers.toString(),
                          ),
                        ),
                        if (summary.unanswered > 0) const SizedBox(width: 12),
                        if (summary.unanswered > 0)
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.help_outline,
                              color: Colors.orange,
                              label: 'Skipped',
                              value: summary.unanswered.toString(),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons
              _buildActionButton(
                context: context,
                label: 'Review Answers',
                icon: Icons.rate_review,
                isPrimary: false,
                onTap: () {
                  // Go back to quiz screen in review mode
                  Navigator.pop(context);
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

  String _getResultTitle(double percentage) {
    if (percentage >= 90) {
      return 'Outstanding! 🎉';
    } else if (percentage >= 80) {
      return 'Great Job! 👏';
    } else if (percentage >= 70) {
      return 'Good Work! 👍';
    } else if (percentage >= 60) {
      return 'Keep Practicing! 💪';
    } else {
      return 'Keep Learning! 📚';
    }
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }
}
