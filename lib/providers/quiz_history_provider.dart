import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_history_response.dart';
import '../providers/documents_provider.dart';
import '../services/documents_service.dart';
import '../services/quiz_history_service.dart';

// Local history service (for backward compatibility)
final quizHistoryServiceProvider = Provider<QuizHistoryService>((ref) {
  return QuizHistoryService();
});

// Backend quiz history provider (fetches from API)
final quizHistoryProvider =
    StateNotifierProvider<QuizHistoryNotifier, AsyncValue<List<QuizAttempts>>>((
      ref,
    ) {
      final documentsService = ref.watch(documentsServiceProvider);
      return QuizHistoryNotifier(documentsService);
    });

class QuizHistoryNotifier
    extends StateNotifier<AsyncValue<List<QuizAttempts>>> {
  final DocumentsService _documentsService;

  QuizHistoryNotifier(this._documentsService)
    : super(const AsyncValue.loading());

  Future<void> loadHistory() async {
    state = const AsyncValue.loading();
    try {
      final history = await _documentsService.getQuizAttemptsList(
        limit: 50,
        offset: 0,
      );
      state = AsyncValue.data(history);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshHistory() async {
    await loadHistory();
  }
}
