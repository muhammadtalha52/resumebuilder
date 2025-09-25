class MeetingSummaryModel {
  final String? status;
  final Summary? summary;

  MeetingSummaryModel({this.status, this.summary});

  factory MeetingSummaryModel.fromJson(dynamic json) {
    return MeetingSummaryModel(
      status: json['status'],
      summary: json['summary'] != null
          ? Summary.fromJson(json['summary'])
          : null,
    );
  }

  MeetingSummaryModel copyWith({
    String? sessionId,
    String? sessionType,
    DateTime? startTime,
    Duration? duration,
    String? status,
    Summary? summary,
  }) {
    return MeetingSummaryModel(
      status: status ?? this.status,
      summary: summary ?? this.summary,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    map['status'] = status;
    if (summary != null) {
      map['summary'] = summary?.toJson();
    }
    return map;
  }
}

class Summary {
  Summary({
    List<String>? keyDiscussionPoints,
    List<String>? decisionsMade,
    List<String>? actionItems,
    List<String>? topMomentsInInterview,
    List<String>? potentialWeaknessOrStrengths,
    List<String>? aiDrivenInterviewAnalytics,
    List<String>? strengthsHighlighted,
    List<String>? areasOfImprovement,
  }) {
    _keyDiscussionPoints = keyDiscussionPoints;
    _decisionsMade = decisionsMade;
    _actionItems = actionItems;
    _topMomentsInInterview = topMomentsInInterview;
    _potentialWeaknessOrStrengths = potentialWeaknessOrStrengths;
    _aiDrivenInterviewAnalytics = aiDrivenInterviewAnalytics;
    _strengthsHighlighted = strengthsHighlighted;
    _areasOfImprovement = areasOfImprovement;
  }

  Summary.fromJson(dynamic json) {
    _keyDiscussionPoints = json['keyDiscussionPoints'] != null
        ? json['keyDiscussionPoints'].cast<String>()
        : [];
    _decisionsMade = json['decisionsMade'] != null
        ? json['decisionsMade'].cast<String>()
        : [];
    _actionItems = json['actionItems'] != null
        ? json['actionItems'].cast<String>()
        : [];
    _topMomentsInInterview = json['topMomentsInInterview'] != null
        ? json['topMomentsInInterview'].cast<String>()
        : [];
    _potentialWeaknessOrStrengths = json['potentialWeaknessOrStrengths'] != null
        ? json['potentialWeaknessOrStrengths'].cast<String>()
        : [];
    _aiDrivenInterviewAnalytics = json['aiDrivenInterviewAnalytics'] != null
        ? json['aiDrivenInterviewAnalytics'].cast<String>()
        : [];
    _strengthsHighlighted = json['strengthsHighlighted'] != null
        ? json['strengthsHighlighted'].cast<String>()
        : [];
    _areasOfImprovement = json['areasOfImprovement'] != null
        ? json['areasOfImprovement'].cast<String>()
        : [];
  }

  List<String>? _keyDiscussionPoints;
  List<String>? _decisionsMade;
  List<String>? _actionItems;
  List<String>? _topMomentsInInterview;
  List<String>? _potentialWeaknessOrStrengths;
  List<String>? _aiDrivenInterviewAnalytics;
  List<String>? _strengthsHighlighted;
  List<String>? _areasOfImprovement;

  List<String>? get keyDiscussionPoints => _keyDiscussionPoints;

  List<String>? get decisionsMade => _decisionsMade;

  List<String>? get actionItems => _actionItems;

  List<String>? get topMomentsInInterview => _topMomentsInInterview;

  List<String>? get potentialWeaknessOrStrengths =>
      _potentialWeaknessOrStrengths;

  List<String>? get aiDrivenInterviewAnalytics => _aiDrivenInterviewAnalytics;

  List<String>? get strengthsHighlighted => _strengthsHighlighted;

  List<String>? get areasOfImprovement => _areasOfImprovement;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['keyDiscussionPoints'] = _keyDiscussionPoints;
    map['decisionsMade'] = _decisionsMade;
    map['actionItems'] = _actionItems;
    map['topMomentsInInterview'] = _topMomentsInInterview;
    map['potentialWeaknessOrStrengths'] = _potentialWeaknessOrStrengths;
    map['aiDrivenInterviewAnalytics'] = _aiDrivenInterviewAnalytics;
    map['strengthsHighlighted'] = _strengthsHighlighted;
    map['areasOfImprovement'] = _areasOfImprovement;
    return map;
  }
}
