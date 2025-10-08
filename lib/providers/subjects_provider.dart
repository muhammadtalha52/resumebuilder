import 'package:flutter_riverpod/flutter_riverpod.dart';

class Subject {
  final String id;
  final String name;
  final String emoji;
  final int lectureCount;
  final int fileCount;

  Subject({
    required this.id,
    required this.name,
    required this.emoji,
    this.lectureCount = 0,
    this.fileCount = 0,
  });

  Subject copyWith({
    String? id,
    String? name,
    String? emoji,
    int? lectureCount,
    int? fileCount,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      lectureCount: lectureCount ?? this.lectureCount,
      fileCount: fileCount ?? this.fileCount,
    );
  }
}

class SubjectsNotifier extends StateNotifier<List<Subject>> {
  SubjectsNotifier() : super([]);

  void addSubject(String name, String emoji) {
    final newSubject = Subject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      emoji: emoji,
    );
    state = [...state, newSubject];
  }

  void removeSubject(String id) {
    state = state.where((subject) => subject.id != id).toList();
  }

  void updateSubject(String id, String name) {
    state = [
      for (final subject in state)
        if (subject.id == id) subject.copyWith(name: name) else subject,
    ];
  }
}

final subjectsProvider = StateNotifierProvider<SubjectsNotifier, List<Subject>>(
  (ref) {
    return SubjectsNotifier();
  },
);
