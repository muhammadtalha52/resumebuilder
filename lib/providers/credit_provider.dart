import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/subscription_service.dart';

// Credit State
class CreditState extends Equatable {
  const CreditState({
    this.isLoading = false,
    this.resumeCredits = 0,
    this.interviewCredits = 0,
    this.error,
  });

  final bool isLoading;
  final int resumeCredits;
  final int interviewCredits;
  final String? error;

  CreditState copyWith({
    bool? isLoading,
    int? resumeCredits,
    int? interviewCredits,
    String? error,
  }) {
    return CreditState(
      isLoading: isLoading ?? this.isLoading,
      resumeCredits: resumeCredits ?? this.resumeCredits,
      interviewCredits: interviewCredits ?? this.interviewCredits,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    resumeCredits,
    interviewCredits,
    error,
  ];
}

// Credit State Notifier
class CreditNotifier extends StateNotifier<CreditState> {
  CreditNotifier() : super(const CreditState()) {
    _initialize();
  }

  late final SubscriptionService _subscriptionService;

  /// Initialize subscription service
  /// Credits start at 0 and should be fetched via refreshCredits()
  void _initialize() {
    try {
      final apiClient = APIClient();
      _subscriptionService = SubscriptionService(apiClient);

      // Credits are now separate from user model
      // They will be fetched from backend when needed via refreshCredits()
    } catch (e) {
      // Continue with default state
    }
  }

  /// Refresh credits from backend
  Future<void> refreshCredits() async {
    state = state.copyWith(isLoading: true);

    try {
      final credits = await _subscriptionService.getCredits();

      if (credits != null) {
        state = state.copyWith(
          isLoading: false,
          resumeCredits: credits.resumeCredits,
          interviewCredits: credits.interviewCredits,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to refresh credits',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error refreshing credits: ${e.toString()}',
      );
    }
  }

  /// Check if user has enough credits for a specific type
  bool hasCredits(String type) {
    if (type == 'resume') {
      return state.resumeCredits > 0;
    } else if (type == 'interview') {
      return state.interviewCredits > 0;
    }
    return false;
  }

  /// Consume a credit (resume or interview)
  /// Returns true if credit was successfully consumed
  Future<bool> consumeCredit(String type) async {
    // Check if user has credits locally first
    if (!hasCredits(type)) {
      state = state.copyWith(error: 'You don\'t have enough $type credits');
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      final response = await _subscriptionService.consumeCredit(type);

      if (response.success) {
        // Update local state
        if (type == 'resume') {
          state = state.copyWith(
            isLoading: false,
            resumeCredits: state.resumeCredits - 1,
            error: null,
          );
        } else if (type == 'interview') {
          state = state.copyWith(
            isLoading: false,
            interviewCredits: state.interviewCredits - 1,
            error: null,
          );
        }

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message ?? 'Failed to consume credit',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error consuming credit: ${e.toString()}',
      );
      return false;
    }
  }

  /// Add credits (used after successful purchase verification)
  void addCredits({required int resumeCredits, required int interviewCredits}) {
    state = state.copyWith(
      resumeCredits: state.resumeCredits + resumeCredits,
      interviewCredits: state.interviewCredits + interviewCredits,
    );
  }

  /// Update credits from user data
  void updateFromUser(int? resumeCredits, int? interviewCredits) {
    state = state.copyWith(
      resumeCredits: resumeCredits ?? 0,
      interviewCredits: interviewCredits ?? 0,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Credit Provider
final creditProvider = StateNotifierProvider<CreditNotifier, CreditState>((
  ref,
) {
  return CreditNotifier();
});
