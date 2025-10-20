import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/quiz_history_response.dart';
import '../../models/quize_model.dart';
import '../../providers/quiz_history_provider.dart';
import '../../widgets/common/custom_app_bar.dart';

class QuizHistoryScreen extends ConsumerStatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  ConsumerState<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends ConsumerState<QuizHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load fresh data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizHistoryProvider.notifier).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(quizHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: const BackNavigationAppBar(title: 'Quiz History'),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/icons/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: historyAsync.when(
          data: (history) {
            if (history.isEmpty) {
              return _buildEmptyState();
            }
            return _buildHistoryList(context, ref, history);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load quiz history',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(quizHistoryProvider.notifier).loadHistory();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(40),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/interview-fox.png', height: 150),
            const SizedBox(height: 32),
            const Text(
              'No Quiz History Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Complete your first quiz to see it here.\nYour quiz history will be saved and you can review them anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    WidgetRef ref,
    List<QuizAttempts> history,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final attempt = history[index];
        return _buildHistoryCard(context, ref, attempt, index);
      },
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    WidgetRef ref,
    QuizAttempts attempt,
    int index,
  ) {
    // Get stats from API response
    final totalQuestions = attempt.totalQuestions ?? 0;
    final correctAnswers = attempt.correctAnswers ?? 0;
    final percentage = double.tryParse(attempt.scorePercentage ?? '0') ?? 0.0;

    // Format date
    String formattedDate = 'Recently';
    if (attempt.completedAt != null) {
      try {
        final date = DateTime.parse(attempt.completedAt!);
        formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);
      } catch (e) {
        // Use default if parsing fails
      }
    }

    // Convert QuizSnapshot to QuizModel for review screen
    QuizModel? quizModel;
    if (attempt.quizSnapshot != null && attempt.quizSnapshot!.isNotEmpty) {
      final items = attempt.quizSnapshot!.map((snapshot) {
        return Items(
          id: snapshot.id,
          question: snapshot.question,
          options: snapshot.options,
          correctLabel: snapshot.correctLabel,
          selectedLabel: snapshot.userAnswer,
        );
      }).toList();
      quizModel = QuizModel(items: items);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: quizModel != null
              ? () {
                  context.push(
                    '/quiz/review?lectureName=Quiz Attempt ${index + 1}',
                    extra: quizModel,
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quiz title
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Quiz ${index + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (quizModel != null)
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    // Score badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(
                          percentage,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getScoreColor(
                            percentage,
                          ).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getScoreIcon(percentage),
                            size: 16,
                            color: _getScoreColor(percentage),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getScoreColor(percentage),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Correct/Total
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$correctAnswers/$totalQuestions correct',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
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

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) {
      return Colors.green;
    } else if (percentage >= 60) {
      return Colors.orange;
    } else {
      return Colors.red.shade400;
    }
  }

  IconData _getScoreIcon(double percentage) {
    if (percentage >= 80) {
      return Icons.check_circle;
    } else if (percentage >= 60) {
      return Icons.info;
    } else {
      return Icons.cancel;
    }
  }
}
