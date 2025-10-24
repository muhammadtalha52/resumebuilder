class StudentDashboardResponse {
  StudentDashboardResponse({String? status, String? message, Data? data}) {
    _status = status;
    _message = message;
    _data = data;
  }

  StudentDashboardResponse.fromJson(dynamic json) {
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
  Data({int? totalQuizzes, int? totalMainFolders, int? totalDocuments}) {
    _totalQuizzes = totalQuizzes;
    _totalMainFolders = totalMainFolders;
    _totalDocuments = totalDocuments;
  }

  Data.fromJson(dynamic json) {
    _totalQuizzes = json['total_quizzes'];
    _totalMainFolders = json['total_main_folders'];
    _totalDocuments = json['total_documents'];
  }

  int? _totalQuizzes;
  int? _totalMainFolders;
  int? _totalDocuments;

  int? get totalQuizzes => _totalQuizzes;

  int? get totalMainFolders => _totalMainFolders;

  int? get totalDocuments => _totalDocuments;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['total_quizzes'] = _totalQuizzes;
    map['total_main_folders'] = _totalMainFolders;
    map['total_documents'] = _totalDocuments;
    return map;
  }
}
