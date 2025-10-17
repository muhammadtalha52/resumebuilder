class QuizModel {
  QuizModel({int? count, List<Items>? items}) {
    _count = count;
    _items = items;
  }

  QuizModel.fromJson(dynamic json) {
    _count = json['count'];
    if (json['items'] != null) {
      _items = [];
      json['items'].forEach((v) {
        _items?.add(Items.fromJson(v));
      });
    }
  }

  int? _count;
  List<Items>? _items;

  int? get count => _count;

  List<Items>? get items => _items;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['count'] = _count;
    if (_items != null) {
      map['items'] = _items?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Items {
  Items({
    int? id,
    String? question,
    Options? options,
    String? correctLabel,
    String? selectedLabel,
    bool? isAnswered,
  }) {
    _id = id;
    _question = question;
    _options = options;
    _correctLabel = correctLabel;
    _selectedLabel = selectedLabel;
    _isAnswered = isAnswered ?? false;
  }

  Items.fromJson(dynamic json) {
    _id = json['id'];
    _question = json['question'];
    _options = json['options'] != null
        ? Options.fromJson(json['options'])
        : null;
    _correctLabel = json['correct_label'];
    _selectedLabel = json['selected_label'];
    _isAnswered = json['selected_label'] != null;
  }

  int? _id;
  String? _question;
  Options? _options;
  String? _correctLabel;
  String? _selectedLabel; // User's selected answer (A, B, C, or D)
  bool _isAnswered = false; // Whether user has checked the answer

  int? get id => _id;

  String? get question => _question;

  Options? get options => _options;

  String? get correctLabel => _correctLabel;

  String? get selectedLabel => _selectedLabel;

  bool get isAnswered => _isAnswered;

  bool get isCorrect => _selectedLabel == _correctLabel;

  // Helper method to select an answer
  void selectAnswer(String label) {
    _selectedLabel = label;
  }

  // Helper method to mark as answered
  void markAsAnswered() {
    _isAnswered = true;
  }

  // Helper method to get options as map for easier iteration
  Map<String, String> getOptionsMap() {
    return {
      'A': _options?.a ?? '',
      'B': _options?.b ?? '',
      'C': _options?.c ?? '',
      'D': _options?.d ?? '',
    };
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['question'] = _question;
    if (_options != null) {
      map['options'] = _options?.toJson();
    }
    map['correct_label'] = _correctLabel;
    map['selected_label'] = _selectedLabel;
    return map;
  }
}

class Options {
  Options({String? a, String? b, String? c, String? d}) {
    _a = a;
    _b = b;
    _c = c;
    _d = d;
  }

  Options.fromJson(dynamic json) {
    _a = json['A'];
    _b = json['B'];
    _c = json['C'];
    _d = json['D'];
  }

  String? _a;
  String? _b;
  String? _c;
  String? _d;

  String? get a => _a;

  String? get b => _b;

  String? get c => _c;

  String? get d => _d;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['A'] = _a;
    map['B'] = _b;
    map['C'] = _c;
    map['D'] = _d;
    return map;
  }
}

/// Helper class to calculate quiz summary/results
class QuizSummary {
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final int unanswered;

  QuizSummary({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.unanswered,
  });

  double get percentage =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

  String get grade {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  factory QuizSummary.fromQuizModel(QuizModel quiz) {
    final items = quiz.items ?? [];
    int correct = 0;
    int incorrect = 0;
    int unanswered = 0;

    for (var item in items) {
      if (!item.isAnswered) {
        unanswered++;
      } else if (item.isCorrect) {
        correct++;
      } else {
        incorrect++;
      }
    }

    return QuizSummary(
      totalQuestions: items.length,
      correctAnswers: correct,
      incorrectAnswers: incorrect,
      unanswered: unanswered,
    );
  }
}
