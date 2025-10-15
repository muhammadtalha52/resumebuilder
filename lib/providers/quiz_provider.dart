import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quize_model.dart';
import '../services/documents_service.dart';
import 'documents_provider.dart';

/// Provider for the documents service
final quizServiceProvider = Provider<DocumentsService>((ref) {
  return ref.read(documentsServiceProvider);
});

/// State notifier for managing quiz state
class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(QuizState.initial());

  /// Load quiz data
  void loadQuiz(QuizModel quiz) {
    state = state.copyWith(quiz: quiz, currentQuestionIndex: 0);
  }

  /// Select an answer for the current question
  void selectAnswer(String label) {
    if (state.quiz == null) return;

    final currentQuestion = state.getCurrentQuestion();
    if (currentQuestion == null || currentQuestion.isAnswered) return;

    currentQuestion.selectAnswer(label);
    state = state.copyWith(quiz: state.quiz);
  }

  /// Check the answer and mark as answered
  void checkAnswer() {
    if (state.quiz == null) return;

    final currentQuestion = state.getCurrentQuestion();
    if (currentQuestion == null || currentQuestion.isAnswered) return;

    currentQuestion.markAsAnswered();
    state = state.copyWith(quiz: state.quiz);
  }

  /// Navigate to next question
  void nextQuestion() {
    if (!state.canGoNext()) return;

    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex + 1,
    );
  }

  /// Navigate to previous question
  void previousQuestion() {
    if (!state.canGoPrevious()) return;

    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex - 1,
    );
  }

  /// Jump to specific question
  void goToQuestion(int index) {
    if (state.quiz == null) return;
    final questions = state.quiz!.items ?? [];
    if (index < 0 || index >= questions.length) return;

    state = state.copyWith(currentQuestionIndex: index);
  }

  /// Get quiz summary
  QuizSummary getSummary() {
    if (state.quiz == null) {
      return QuizSummary(
        totalQuestions: 0,
        correctAnswers: 0,
        incorrectAnswers: 0,
        unanswered: 0,
      );
    }
    return QuizSummary.fromQuizModel(state.quiz!);
  }

  /// Reset quiz state
  void reset() {
    state = QuizState.initial();
  }
}

/// Quiz state class
class QuizState {
  final QuizModel? quiz;
  final int currentQuestionIndex;

  QuizState({required this.quiz, required this.currentQuestionIndex});

  factory QuizState.initial() {
    return QuizState(quiz: null, currentQuestionIndex: 0);
  }

  QuizState copyWith({QuizModel? quiz, int? currentQuestionIndex}) {
    return QuizState(
      quiz: quiz ?? this.quiz,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    );
  }

  /// Get current question
  Items? getCurrentQuestion() {
    if (quiz == null) return null;
    final questions = quiz!.items ?? [];
    if (currentQuestionIndex < 0 || currentQuestionIndex >= questions.length) {
      return null;
    }
    return questions[currentQuestionIndex];
  }

  /// Get total questions count
  int getTotalQuestions() {
    return quiz?.items?.length ?? 0;
  }

  /// Check if can go to next question
  bool canGoNext() {
    return currentQuestionIndex < getTotalQuestions() - 1;
  }

  /// Check if can go to previous question
  bool canGoPrevious() {
    return currentQuestionIndex > 0;
  }

  /// Check if on last question
  bool isLastQuestion() {
    return currentQuestionIndex == getTotalQuestions() - 1;
  }

  /// Check if all questions are answered
  bool isQuizCompleted() {
    if (quiz == null) return false;
    final questions = quiz!.items ?? [];
    return questions.every((q) => q.isAnswered);
  }

  /// Get progress percentage (0-100)
  double getProgressPercentage() {
    if (quiz == null) return 0;
    final total = getTotalQuestions();
    if (total == 0) return 0;
    return ((currentQuestionIndex + 1) / total) * 100;
  }
}

/// Provider for quiz state
final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier();
});

/// Provider to generate quiz from documents
final generateQuizProvider = FutureProvider.family<QuizModel, List<String>>((
  ref,
  s3Filenames,
) async {
  final service = ref.read(quizServiceProvider);
  return await service.generateQuiz(s3Filenames: s3Filenames);
});
