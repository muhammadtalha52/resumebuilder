import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/quiz_history_provider.dart';
import '../../providers/documents_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../utils/snackbar_utils.dart' as snackbar;

class QuizSummaryScreen extends ConsumerStatefulWidget {
  final String lectureName;

  const QuizSummaryScreen({super.key, required this.lectureName});

  @override
  ConsumerState<QuizSummaryScreen> createState() => _QuizSummaryScreenState();
}

class _QuizSummaryScreenState extends ConsumerState<QuizSummaryScreen> {
  bool _isSaving = false;

  Future<bool> _saveQuizToBackend() async {
    if (_isSaving) return false;

    setState(() {
      _isSaving = true;
    });

    final quizState = ref.read(quizProvider);

    if (quizState.quiz != null) {
      try {
        // Save to backend
        final documentsService = ref.read(documentsServiceProvider);
        await documentsService.saveQuizAttempt(quizModel: quizState.quiz!);

        // Refresh history
        ref.read(quizHistoryProvider.notifier).loadHistory();

        if (mounted) {
          snackbar.showSuccessSnackBar(
            context: context,
            message: 'Quiz saved successfully!',
          );
        }

        setState(() {
          _isSaving = false;
        });

        return true;
      } catch (e) {
        print('❌ Error saving quiz: $e');
        if (mounted) {
          snackbar.showErrorSnackBar(
            context: context,
            message: 'Failed to save quiz: ${e.toString()}',
          );
        }

        setState(() {
          _isSaving = false;
        });

        return false;
      }
    }

    setState(() {
      _isSaving = false;
    });

    return false;
  }

  Future<void> _handleBackPress() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _SaveQuizDialog(
        title: 'Save Your Results',
        subtitle:
            'Your quiz results will be saved to your history. You can review them anytime!',
        icon: Icons.bookmark_added,
        confirmText: 'Save & Exit',
        onSave: () async {
          final saved = await _saveQuizToBackend();
          if (saved && mounted) {
            Navigator.of(dialogContext).pop();
            ref.read(quizProvider.notifier).reset();
            Navigator.of(context).pop();
          }
          return saved;
        },
      ),
    );
  }

  Future<void> _handleDonePress() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _SaveQuizDialog(
        title: 'Great Job!',
        subtitle:
            'Let\'s save your quiz results to your history so you can track your progress and review them anytime!',
        icon: Icons.workspace_premium,
        confirmText: 'Save',
        onSave: () async {
          final saved = await _saveQuizToBackend();
          if (saved && mounted) {
            Navigator.of(dialogContext).pop();
            ref.read(quizProvider.notifier).reset();
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
          return saved;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.read(quizProvider.notifier).getSummary();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: BackNavigationAppBar(
        title: 'Quiz Results',
        onBackPressed: _handleBackPress,
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
                  onTap: _handleDonePress,
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
      return 'Don\'t be discouraged. Consistent practice and review will lead to steady improvement.';
    }
  }
}

// Custom Save Quiz Dialog with loading state
class _SaveQuizDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String confirmText;
  final Future<bool> Function() onSave;

  const _SaveQuizDialog({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.confirmText,
    required this.onSave,
  });

  @override
  State<_SaveQuizDialog> createState() => _SaveQuizDialogState();
}

class _SaveQuizDialogState extends State<_SaveQuizDialog> {
  bool _isLoading = false;

  Future<void> _handleSave() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    await widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isLoading
                            ? const Color(0xFFE5E7EB).withValues(alpha: 0.5)
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isLoading
                                ? const Color(0xFF6B7280).withValues(alpha: 0.5)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Save button
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _handleSave,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isLoading
                            ? AppColors.primary.withValues(alpha: 0.6)
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                widget.confirmText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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
    );
  }
}
