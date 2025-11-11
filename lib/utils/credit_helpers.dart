import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/credit_provider.dart';
import '../widgets/dialogs/paywall_dialog.dart';

/// Helper class for credit checking and consumption
class CreditHelpers {
  /// Check if user has resume credits and show paywall if not
  /// Returns true if user has credits and can proceed
  static Future<bool> checkResumeCredits(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final creditNotifier = ref.read(creditProvider.notifier);

    if (!creditNotifier.hasCredits('resume')) {
      // Show paywall dialog
      if (context.mounted) {
        await showPaywallDialog(context, 'resume');
      }
      return false;
    }

    return true;
  }

  /// Check if user has interview credits and show paywall if not
  /// Returns true if user has credits and can proceed
  static Future<bool> checkInterviewCredits(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final creditNotifier = ref.read(creditProvider.notifier);

    if (!creditNotifier.hasCredits('interview')) {
      // Show paywall dialog
      if (context.mounted) {
        await showPaywallDialog(context, 'interview');
      }
      return false;
    }

    return true;
  }

  /// Consume a resume credit (call after successful resume generation)
  /// Shows error if consumption fails
  static Future<bool> consumeResumeCredit(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final creditNotifier = ref.read(creditProvider.notifier);
    final success = await creditNotifier.consumeCredit('resume');

    if (!success && context.mounted) {
      final creditState = ref.read(creditProvider);
      if (creditState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(creditState.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return success;
  }

  /// Consume an interview credit (call after successful interview start)
  /// Shows error if consumption fails
  static Future<bool> consumeInterviewCredit(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final creditNotifier = ref.read(creditProvider.notifier);
    final success = await creditNotifier.consumeCredit('interview');

    if (!success && context.mounted) {
      final creditState = ref.read(creditProvider);
      if (creditState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(creditState.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return success;
  }

  /// Combined check and consume for resume generation
  /// Call this before generating a resume
  /// Returns true if check passed and credit consumed
  static Future<bool> checkAndPrepareResumeGeneration(
    BuildContext context,
    WidgetRef ref,
  ) async {
    return await checkResumeCredits(context, ref);
  }

  /// Combined check and consume for interview session
  /// Call this before starting an interview
  /// Returns true if check passed and credit consumed
  static Future<bool> checkAndPrepareInterviewSession(
    BuildContext context,
    WidgetRef ref,
  ) async {
    return await checkInterviewCredits(context, ref);
  }

  /// Refresh credits from backend
  static Future<void> refreshCredits(WidgetRef ref) async {
    await ref.read(creditProvider.notifier).refreshCredits();
  }
}
