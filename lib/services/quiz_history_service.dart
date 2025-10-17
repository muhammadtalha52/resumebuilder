import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quize_model.dart';

class QuizHistoryItem {
  final String id;
  final String lectureName;
  final QuizModel quiz;
  final DateTime completedAt;
  final int correctAnswers;
  final int totalQuestions;

  QuizHistoryItem({
    required this.id,
    required this.lectureName,
    required this.quiz,
    required this.completedAt,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  double get percentage =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lectureName': lectureName,
      'quiz': quiz.toJson(),
      'completedAt': completedAt.toIso8601String(),
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
    };
  }

  factory QuizHistoryItem.fromJson(Map<String, dynamic> json) {
    return QuizHistoryItem(
      id: json['id'] as String,
      lectureName: json['lectureName'] as String,
      quiz: QuizModel.fromJson(json['quiz'] as Map<String, dynamic>),
      completedAt: DateTime.parse(json['completedAt'] as String),
      correctAnswers: json['correctAnswers'] as int,
      totalQuestions: json['totalQuestions'] as int,
    );
  }
}

class QuizHistoryService {
  static const String _storageKey = 'quiz_history';
  static const int _maxHistoryItems = 50;

  Future<List<QuizHistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => QuizHistoryItem.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    } catch (e) {
      return [];
    }
  }

  Future<void> saveQuiz({
    required String lectureName,
    required QuizModel quiz,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();

      final newItem = QuizHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        lectureName: lectureName,
        quiz: quiz,
        completedAt: DateTime.now(),
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
      );

      history.insert(0, newItem);

      // Keep only the most recent items
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      final jsonString = json.encode(
        history.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  Future<QuizHistoryItem?> getQuizById(String id) async {
    try {
      final history = await getHistory();
      return history.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteQuiz(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();

      history.removeWhere((item) => item.id == id);

      final jsonString = json.encode(
        history.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      // Handle error silently or log it
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      // Handle error silently or log it
    }
  }
}
