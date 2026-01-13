class MeetingSummaryModel {
  final String? status;
  final Summary? summary;
  final Duration? duration;
  final String? sessionId;
  final String? sessionType;
  final DateTime? startTime;

  MeetingSummaryModel({
    this.status,
    this.summary,
    this.duration,
    this.sessionId,
    this.sessionType,
    this.startTime,
  });

  factory MeetingSummaryModel.fromJson(dynamic json) {
    return MeetingSummaryModel(
      status: json['status'],
      summary: json['summary'] != null
          ? Summary.fromJson(json['summary'])
          : null,
    );
  }

  // Convenience getter to access meetingSummary from Summary
  String? get meetingSummary => summary?.meetingSummary;

  // Convenience getter to access interviewSummary from Summary
  String? get interviewSummary => summary?.interviewSummary;

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
      duration: duration ?? this.duration,
      sessionId: sessionId ?? this.sessionId,
      sessionType: sessionType ?? this.sessionType,
      startTime: startTime ?? this.startTime,
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
    List<String>? candidateActionItems,
    List<String>? topMomentsInInterview,
    List<String>? potentialWeaknessOrStrengths,
    List<String>? aiDrivenInterviewAnalytics,
    List<String>? strengthsHighlighted,
    List<String>? areasOfImprovement,
    List<String>? meetingSummaryList,
    List<String>? interviewSummaryList,
  }) {
    _keyDiscussionPoints = keyDiscussionPoints;
    _decisionsMade = decisionsMade;
    _actionItems = actionItems;
    _candidateActionItems = candidateActionItems;
    _topMomentsInInterview = topMomentsInInterview;
    _potentialWeaknessOrStrengths = potentialWeaknessOrStrengths;
    _aiDrivenInterviewAnalytics = aiDrivenInterviewAnalytics;
    _strengthsHighlighted = strengthsHighlighted;
    _areasOfImprovement = areasOfImprovement;
    _meetingSummaryList = meetingSummaryList;
    _interviewSummaryList = interviewSummaryList;
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
    _candidateActionItems = json['candidateActionItems'] != null
        ? json['candidateActionItems'].cast<String>()
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
    _meetingSummaryList = json['meetingSummary'] != null
        ? json['meetingSummary'].cast<String>()
        : [];
    _interviewSummaryList = json['interviewSummary'] != null
        ? json['interviewSummary'].cast<String>()
        : [];
  }

  List<String>? _keyDiscussionPoints;
  List<String>? _decisionsMade;
  List<String>? _actionItems;
  List<String>? _candidateActionItems;
  List<String>? _topMomentsInInterview;
  List<String>? _potentialWeaknessOrStrengths;
  List<String>? _aiDrivenInterviewAnalytics;
  List<String>? _strengthsHighlighted;
  List<String>? _areasOfImprovement;
  List<String>? _meetingSummaryList;
  List<String>? _interviewSummaryList;

  List<String>? get keyDiscussionPoints => _keyDiscussionPoints;

  List<String>? get decisionsMade => _decisionsMade;

  List<String>? get actionItems => _actionItems;

  List<String>? get candidateActionItems => _candidateActionItems;

  List<String>? get topMomentsInInterview => _topMomentsInInterview;

  List<String>? get potentialWeaknessOrStrengths =>
      _potentialWeaknessOrStrengths;

  List<String>? get aiDrivenInterviewAnalytics => _aiDrivenInterviewAnalytics;

  List<String>? get strengthsHighlighted => _strengthsHighlighted;

  List<String>? get areasOfImprovement => _areasOfImprovement;

  List<String>? get meetingSummaryList => _meetingSummaryList;

  List<String>? get interviewSummaryList => _interviewSummaryList;

  // Convenience getter: joins array into single string for display
  String? get meetingSummary {
    if (_meetingSummaryList == null || _meetingSummaryList!.isEmpty) {
      return null;
    }
    return _meetingSummaryList!.join('\n\n');
  }

  // Convenience getter: joins array into single string for display
  String? get interviewSummary {
    if (_interviewSummaryList == null || _interviewSummaryList!.isEmpty) {
      return null;
    }
    return _interviewSummaryList!.join('\n\n');
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['keyDiscussionPoints'] = _keyDiscussionPoints;
    map['decisionsMade'] = _decisionsMade;
    map['actionItems'] = _actionItems;
    map['candidateActionItems'] = _candidateActionItems;
    map['topMomentsInInterview'] = _topMomentsInInterview;
    map['potentialWeaknessOrStrengths'] = _potentialWeaknessOrStrengths;
    map['aiDrivenInterviewAnalytics'] = _aiDrivenInterviewAnalytics;
    map['strengthsHighlighted'] = _strengthsHighlighted;
    map['areasOfImprovement'] = _areasOfImprovement;
    map['meetingSummary'] = _meetingSummaryList;
    map['interviewSummary'] = _interviewSummaryList;
    return map;
  }
}
