import 'package:flutter_riverpod/flutter_riverpod.dart';

class Lecture {
  final String id;
  final String name;
  final String subjectId;
  final int documentCount;
  final DateTime createdAt;

  Lecture({
    required this.id,
    required this.name,
    required this.subjectId,
    this.documentCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Lecture copyWith({
    String? id,
    String? name,
    String? subjectId,
    int? documentCount,
    DateTime? createdAt,
  }) {
    return Lecture(
      id: id ?? this.id,
      name: name ?? this.name,
      subjectId: subjectId ?? this.subjectId,
      documentCount: documentCount ?? this.documentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class LecturesNotifier extends StateNotifier<List<Lecture>> {
  LecturesNotifier() : super([]);

  void addLecture(String name, String subjectId) {
    final newLecture = Lecture(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      subjectId: subjectId,
    );
    state = [...state, newLecture];
  }

  void removeLecture(String id) {
    state = state.where((lecture) => lecture.id != id).toList();
  }

  void updateLecture(String id, String name) {
    state = [
      for (final lecture in state)
        if (lecture.id == id) lecture.copyWith(name: name) else lecture,
    ];
  }

  List<Lecture> getLecturesForSubject(String subjectId) {
    return state.where((lecture) => lecture.subjectId == subjectId).toList();
  }

  int getLectureCountForSubject(String subjectId) {
    return state.where((lecture) => lecture.subjectId == subjectId).length;
  }
}

final lecturesProvider = StateNotifierProvider<LecturesNotifier, List<Lecture>>(
  (ref) {
    return LecturesNotifier();
  },
);
