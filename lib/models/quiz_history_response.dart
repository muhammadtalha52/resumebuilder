import 'package:skillresy/models/quize_model.dart';

class QuizHistoryResponse {
  QuizHistoryResponse({String? status, String? message, Data? data}) {
    _status = status;
    _message = message;
    _data = data;
  }

  QuizHistoryResponse.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  String? _status;
  String? _message;
  Data? _data;

  String? get status => _status;

  String? get message => _message;

  Data? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}

class Data {
  Data({List<QuizAttempts>? quizAttempts, Pagination? pagination}) {
    _quizAttempts = quizAttempts;
    _pagination = pagination;
  }

  Data.fromJson(dynamic json) {
    if (json['quiz_attempts'] != null) {
      _quizAttempts = [];
      json['quiz_attempts'].forEach((v) {
        _quizAttempts?.add(QuizAttempts.fromJson(v));
      });
    }
    _pagination = json['pagination'] != null
        ? Pagination.fromJson(json['pagination'])
        : null;
  }

  List<QuizAttempts>? _quizAttempts;
  Pagination? _pagination;

  List<QuizAttempts>? get quizAttempts => _quizAttempts;

  Pagination? get pagination => _pagination;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_quizAttempts != null) {
      map['quiz_attempts'] = _quizAttempts?.map((v) => v.toJson()).toList();
    }
    if (_pagination != null) {
      map['pagination'] = _pagination?.toJson();
    }
    return map;
  }
}

class Pagination {
  Pagination({int? totalCount, int? limit, int? offset, bool? hasMore}) {
    _totalCount = totalCount;
    _limit = limit;
    _offset = offset;
    _hasMore = hasMore;
  }

  Pagination.fromJson(dynamic json) {
    _totalCount = json['total_count'];
    _limit = json['limit'];
    _offset = json['offset'];
    _hasMore = json['has_more'];
  }

  int? _totalCount;
  int? _limit;
  int? _offset;
  bool? _hasMore;

  int? get totalCount => _totalCount;

  int? get limit => _limit;

  int? get offset => _offset;

  bool? get hasMore => _hasMore;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['total_count'] = _totalCount;
    map['limit'] = _limit;
    map['offset'] = _offset;
    map['has_more'] = _hasMore;
    return map;
  }
}

class QuizAttempts {
  QuizAttempts({
    int? id,
    int? user,
    dynamic quiz,
    int? quizId,
    List<QuizSnapshot>? quizSnapshot,
    int? totalQuestions,
    int? questionsAttempted,
    int? correctAnswers,
    int? wrongAnswers,
    String? scorePercentage,
    String? startedAt,
    String? completedAt,
    bool? isCompleted,
    List<Answers>? answers,
  }) {
    _id = id;
    _user = user;
    _quiz = quiz;
    _quizId = quizId;
    _quizSnapshot = quizSnapshot;
    _totalQuestions = totalQuestions;
    _questionsAttempted = questionsAttempted;
    _correctAnswers = correctAnswers;
    _wrongAnswers = wrongAnswers;
    _scorePercentage = scorePercentage;
    _startedAt = startedAt;
    _completedAt = completedAt;
    _isCompleted = isCompleted;
    _answers = answers;
  }

  QuizAttempts.fromJson(dynamic json) {
    _id = json['id'];
    _user = json['user'];
    _quiz = json['quiz'];
    _quizId = json['quiz_id'];
    if (json['quiz_snapshot'] != null) {
      _quizSnapshot = [];
      json['quiz_snapshot'].forEach((v) {
        _quizSnapshot?.add(QuizSnapshot.fromJson(v));
      });
    }
    _totalQuestions = json['total_questions'];
    _questionsAttempted = json['questions_attempted'];
    _correctAnswers = json['correct_answers'];
    _wrongAnswers = json['wrong_answers'];
    _scorePercentage = json['score_percentage'];
    _startedAt = json['started_at'];
    _completedAt = json['completed_at'];
    _isCompleted = json['is_completed'];
    if (json['answers'] != null) {
      _answers = [];
      json['answers'].forEach((v) {
        _answers?.add(Answers.fromJson(v));
      });
    }
  }

  int? _id;
  int? _user;
  dynamic _quiz;
  int? _quizId;
  List<QuizSnapshot>? _quizSnapshot;
  int? _totalQuestions;
  int? _questionsAttempted;
  int? _correctAnswers;
  int? _wrongAnswers;
  String? _scorePercentage;
  String? _startedAt;
  String? _completedAt;
  bool? _isCompleted;
  List<Answers>? _answers;

  int? get id => _id;

  int? get user => _user;

  dynamic get quiz => _quiz;

  int? get quizId => _quizId;

  List<QuizSnapshot>? get quizSnapshot => _quizSnapshot;

  int? get totalQuestions => _totalQuestions;

  int? get questionsAttempted => _questionsAttempted;

  int? get correctAnswers => _correctAnswers;

  int? get wrongAnswers => _wrongAnswers;

  String? get scorePercentage => _scorePercentage;

  String? get startedAt => _startedAt;

  String? get completedAt => _completedAt;

  bool? get isCompleted => _isCompleted;

  List<Answers>? get answers => _answers;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['user'] = _user;
    map['quiz'] = _quiz;
    map['quiz_id'] = _quizId;
    if (_quizSnapshot != null) {
      map['quiz_snapshot'] = _quizSnapshot?.map((v) => v.toJson()).toList();
    }
    map['total_questions'] = _totalQuestions;
    map['questions_attempted'] = _questionsAttempted;
    map['correct_answers'] = _correctAnswers;
    map['wrong_answers'] = _wrongAnswers;
    map['score_percentage'] = _scorePercentage;
    map['started_at'] = _startedAt;
    map['completed_at'] = _completedAt;
    map['is_completed'] = _isCompleted;
    if (_answers != null) {
      map['answers'] = _answers?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Answers {
  Answers({
    int? id,
    int? questionId,
    String? questionText,
    Options? options,
    String? correctLabel,
    String? userAnswer,
    bool? isCorrect,
    String? answeredAt,
  }) {
    _id = id;
    _questionId = questionId;
    _questionText = questionText;
    _options = options;
    _correctLabel = correctLabel;
    _userAnswer = userAnswer;
    _isCorrect = isCorrect;
    _answeredAt = answeredAt;
  }

  Answers.fromJson(dynamic json) {
    _id = json['id'];
    _questionId = json['question_id'];
    _questionText = json['question_text'];
    _options = json['options'] != null
        ? Options.fromJson(json['options'])
        : null;
    _correctLabel = json['correct_label'];
    _userAnswer = json['user_answer'];
    _isCorrect = json['is_correct'];
    _answeredAt = json['answered_at'];
  }

  int? _id;
  int? _questionId;
  String? _questionText;
  Options? _options;
  String? _correctLabel;
  String? _userAnswer;
  bool? _isCorrect;
  String? _answeredAt;

  int? get id => _id;

  int? get questionId => _questionId;

  String? get questionText => _questionText;

  Options? get options => _options;

  String? get correctLabel => _correctLabel;

  String? get userAnswer => _userAnswer;

  bool? get isCorrect => _isCorrect;

  String? get answeredAt => _answeredAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['question_id'] = _questionId;
    map['question_text'] = _questionText;
    if (_options != null) {
      map['options'] = _options?.toJson();
    }
    map['correct_label'] = _correctLabel;
    map['user_answer'] = _userAnswer;
    map['is_correct'] = _isCorrect;
    map['answered_at'] = _answeredAt;
    return map;
  }
}

class QuizSnapshot {
  QuizSnapshot({
    int? id,
    Options? options,
    String? question,
    String? userAnswer,
    String? correctLabel,
  }) {
    _id = id;
    _options = options;
    _question = question;
    _userAnswer = userAnswer;
    _correctLabel = correctLabel;
  }

  QuizSnapshot.fromJson(dynamic json) {
    _id = json['id'];
    _options = json['options'] != null
        ? Options.fromJson(json['options'])
        : null;
    _question = json['question'];
    _userAnswer = json['user_answer'];
    _correctLabel = json['correct_label'];
  }

  int? _id;
  Options? _options;
  String? _question;
  String? _userAnswer;
  String? _correctLabel;

  int? get id => _id;

  Options? get options => _options;

  String? get question => _question;

  String? get userAnswer => _userAnswer;

  String? get correctLabel => _correctLabel;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    if (_options != null) {
      map['options'] = _options?.toJson();
    }
    map['question'] = _question;
    map['user_answer'] = _userAnswer;
    map['correct_label'] = _correctLabel;
    return map;
  }
}
