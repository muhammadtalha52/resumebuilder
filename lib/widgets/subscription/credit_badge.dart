import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/credit_provider.dart';

/// Widget to display remaining credits (resume and interview)
class CreditBadge extends ConsumerWidget {
  final bool showResume;
  final bool showInterview;
  final bool compact;

  const CreditBadge({
    super.key,
    this.showResume = true,
    this.showInterview = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditState = ref.watch(creditProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!showResume && !showInterview) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return _buildCompactBadge(context, creditState, colorScheme);
    }

    return _buildFullBadge(context, creditState, colorScheme);
  }

  Widget _buildFullBadge(
    BuildContext context,
    CreditState creditState,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showResume) ...[
            Icon(
              Icons.description_outlined,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '${creditState.resumeCredits}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (showResume && showInterview) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              height: 16,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ],
          if (showInterview) ...[
            Icon(
              Icons.video_call_outlined,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '${creditState.interviewCredits}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactBadge(
    BuildContext context,
    CreditState creditState,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.bolt, size: 16, color: colorScheme.primary),
    );
  }
}

/// Widget to display a single credit type (resume OR interview)
class SingleCreditBadge extends ConsumerWidget {
  final String type; // 'resume' or 'interview'

  const SingleCreditBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditState = ref.watch(creditProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final credits = type == 'resume'
        ? creditState.resumeCredits
        : creditState.interviewCredits;

    final icon = type == 'resume'
        ? Icons.description_outlined
        : Icons.video_call_outlined;

    final label = type == 'resume' ? 'Resumes' : 'Interviews';

    final isLow = credits < 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLow
            ? colorScheme.errorContainer.withValues(alpha: 0.3)
            : colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLow
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isLow ? colorScheme.error : colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$credits',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isLow ? colorScheme.error : colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isLow
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
