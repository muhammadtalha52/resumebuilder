import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quiz_history_service.dart';

final quizHistoryServiceProvider = Provider<QuizHistoryService>((ref) {
  return QuizHistoryService();
});

final quizHistoryProvider =
    StateNotifierProvider<
      QuizHistoryNotifier,
      AsyncValue<List<QuizHistoryItem>>
    >((ref) {
      final service = ref.watch(quizHistoryServiceProvider);
      return QuizHistoryNotifier(service);
    });

class QuizHistoryNotifier
    extends StateNotifier<AsyncValue<List<QuizHistoryItem>>> {
  final QuizHistoryService _service;

  QuizHistoryNotifier(this._service) : super(const AsyncValue.loading()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = const AsyncValue.loading();
    try {
      final history = await _service.getHistory();
      state = AsyncValue.data(history);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteQuiz(String id) async {
    try {
      await _service.deleteQuiz(id);
      await loadHistory();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> clearHistory() async {
    try {
      await _service.clearHistory();
      state = const AsyncValue.data([]);
    } catch (e) {
      // Handle error
    }
  }

  List<QuizHistoryItem> getHistoryByLecture(String lectureName) {
    return state.maybeWhen(
      data: (history) =>
          history.where((item) => item.lectureName == lectureName).toList(),
      orElse: () => [],
    );
  }
}
