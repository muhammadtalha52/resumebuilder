class InterviewSessionData {
  // ===== SETUP PHASE DATA =====
  String companyName;
  String positionTitle;
  String interviewType;
  String roleIndustry;
  String jobDescription;
  String languageSelector;
  String interviewerName;
  String interviewerEmail;
  String location;
  String notes;
  String meetingAgenda;

  // ===== SESSION PHASE DATA =====
  String? sessionId; // Generated when session starts
  DateTime? startTime; // When session begins
  DateTime? endTime; // When session ends
  Duration? duration; // Calculated duration
  String status; // 'setup' → 'active' → 'completed' → 'saved'
  String? fullTranscript; // Complete conversation
  String? transcript; // Real-time transcript

  // ===== LOADING STATES =====
  bool isStartingSession; // Loading state for session start
  String? error; // Error message if any

  // ===== SUMMARY PHASE DATA =====
  List<String> keyTopics; // Extracted from AI summary
  List<String> strengthHighlight;
  List<String> weaknessHighlight;
  List<String> actionItems;
  String? rawSummary; // Original AI response
  bool saved; // Whether saved to database
  DateTime? savedAt; // When it was saved

  InterviewSessionData({
    // Setup data
    this.companyName = '',
    this.positionTitle = '',
    this.interviewType = '',
    this.roleIndustry = '',
    this.jobDescription = '',
    this.languageSelector = 'English',
    this.interviewerName = '',
    this.interviewerEmail = '',
    this.location = '',
    this.notes = '',
    this.meetingAgenda = '',

    // Session data
    this.sessionId,
    this.startTime,
    this.endTime,
    this.duration,
    this.status = 'setup',
    this.fullTranscript,
    this.transcript,

    // Loading states
    this.isStartingSession = false,
    this.error,

    // Summary data
    this.keyTopics = const [],
    this.strengthHighlight = const [],
    this.weaknessHighlight = const [],
    this.actionItems = const [],
    this.rawSummary,
    this.saved = false,
    this.savedAt,
  });

  // Calculate duration if not set
  Duration get calculatedDuration {
    if (duration != null) return duration!;
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return Duration.zero;
  }

  // Check if setup phase is complete
  bool get isSetupComplete {
    return companyName.isNotEmpty &&
        positionTitle.isNotEmpty &&
        interviewType.isNotEmpty;
  }

  // Check if session is active
  bool get isSessionActive {
    return status == 'active' && sessionId != null;
  }

  // Check if session is completed
  bool get isSessionCompleted {
    return status == 'completed' || status == 'saved';
  }

  // Start the session
  InterviewSessionData startSession({
    required String sessionId,
    DateTime? startTime,
  }) {
    return copyWith(
      sessionId: sessionId,
      startTime: startTime ?? DateTime.now(),
      status: 'active',
    );
  }

  // End the session
  InterviewSessionData endSession({DateTime? endTime, String? fullTranscript}) {
    final endDateTime = endTime ?? DateTime.now();
    final sessionDuration = startTime != null
        ? endDateTime.difference(startTime!)
        : Duration.zero;

    return copyWith(
      endTime: endDateTime,
      duration: sessionDuration,
      status: 'completed',
      fullTranscript: fullTranscript,
    );
  }

  // Add summary data
  InterviewSessionData addSummary({
    required List<String> keyTopics,
    required List<String> strengthHighlight,
    required List<String> weaknessHighlight,
    required List<String> actionItems,
    String? rawSummary,
  }) {
    return copyWith(
      keyTopics: keyTopics,
      strengthHighlight: strengthHighlight,
      weaknessHighlight: weaknessHighlight,
      actionItems: actionItems,
      rawSummary: rawSummary,
    );
  }

  // Mark as saved
  InterviewSessionData markAsSaved() {
    return copyWith(saved: true, savedAt: DateTime.now(), status: 'saved');
  }

  // Convert to API format for saving
  Map<String, dynamic> toApiJson() {
    return {
      'company_name': companyName,
      'position_title': positionTitle,
      'interview_type': interviewType,
      'role_industry': roleIndustry,
      'job_description': jobDescription,
      'language_selector': languageSelector,
      'status': status,
      'interview_date': startTime?.toIso8601String(),
      'duration_minutes': calculatedDuration.inMinutes,
      'location': location,
      'interviewer_name': interviewerName,
      'interviewer_email': interviewerEmail,
      'notes': notes,
      'meeting_agenda': meetingAgenda,
      'key_topics': keyTopics,
      'strength_highlight': strengthHighlight,
      'weakness_highlight': weaknessHighlight,
      'action_items': actionItems,
      'transcript': transcript,
    };
  }

  // Create from JSON (for persistence/loading)
  factory InterviewSessionData.fromJson(Map<String, dynamic> json) {
    return InterviewSessionData(
      companyName: json['company_name'] ?? '',
      positionTitle: json['position_title'] ?? '',
      interviewType: json['interview_type'] ?? '',
      roleIndustry: json['role_industry'] ?? '',
      jobDescription: json['job_description'] ?? '',
      languageSelector: json['language_selector'] ?? 'English',
      interviewerName: json['interviewer_name'] ?? '',
      interviewerEmail: json['interviewer_email'] ?? '',
      location: json['location'] ?? '',
      notes: json['notes'] ?? '',
      meetingAgenda: json['meeting_agenda'] ?? '',

      sessionId: json['session_id'],
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      duration: json['duration_seconds'] != null
          ? Duration(seconds: json['duration_seconds'])
          : null,
      status: json['status'] ?? 'setup',
      fullTranscript: json['full_transcript'],
      transcript: json['transcript'],
      keyTopics: List<String>.from(json['key_topics'] ?? []),
      strengthHighlight: List<String>.from(json['strength_highlight'] ?? []),
      weaknessHighlight: List<String>.from(json['weakness_highlight'] ?? []),
      actionItems: List<String>.from(json['action_items'] ?? []),
      rawSummary: json['raw_summary'],
      saved: json['saved'] ?? false,
      savedAt: json['saved_at'] != null
          ? DateTime.parse(json['saved_at'])
          : null,
    );
  }

  // Convert to JSON (for persistence/saving)
  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'position_title': positionTitle,
      'interview_type': interviewType,
      'role_industry': roleIndustry,
      'job_description': jobDescription,
      'language_selector': languageSelector,
      'interviewer_name': interviewerName,
      'interviewer_email': interviewerEmail,
      'location': location,
      'notes': notes,
      'meeting_agenda': meetingAgenda,
      'session_id': sessionId,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': duration?.inSeconds,
      'status': status,
      'full_transcript': fullTranscript,
      'transcript': transcript,
      'key_topics': keyTopics,
      'strength_highlight': strengthHighlight,
      'weakness_highlight': weaknessHighlight,
      'action_items': actionItems,
      'raw_summary': rawSummary,
      'saved': saved,
      'saved_at': savedAt?.toIso8601String(),
    };
  }

  // CopyWith method for immutable updates
  InterviewSessionData copyWith({
    String? companyName,
    String? positionTitle,
    String? interviewType,
    String? roleIndustry,
    String? jobDescription,
    String? languageSelector,
    String? interviewerName,
    String? interviewerEmail,
    String? location,
    String? notes,
    String? meetingAgenda,
    String? sessionId,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    String? status,
    String? fullTranscript,
    String? transcript,
    bool? isStartingSession,
    String? error,
    List<String>? keyTopics,
    List<String>? strengthHighlight,
    List<String>? weaknessHighlight,
    List<String>? actionItems,
    String? rawSummary,
    bool? saved,
    DateTime? savedAt,
  }) {
    return InterviewSessionData(
      companyName: companyName ?? this.companyName,
      positionTitle: positionTitle ?? this.positionTitle,
      interviewType: interviewType ?? this.interviewType,
      roleIndustry: roleIndustry ?? this.roleIndustry,
      jobDescription: jobDescription ?? this.jobDescription,
      languageSelector: languageSelector ?? this.languageSelector,
      interviewerName: interviewerName ?? this.interviewerName,
      interviewerEmail: interviewerEmail ?? this.interviewerEmail,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      meetingAgenda: meetingAgenda ?? this.meetingAgenda,
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      fullTranscript: fullTranscript ?? this.fullTranscript,
      transcript: transcript ?? this.transcript,
      isStartingSession: isStartingSession ?? this.isStartingSession,
      error: error ?? this.error,
      keyTopics: keyTopics ?? this.keyTopics,
      strengthHighlight: strengthHighlight ?? this.strengthHighlight,
      weaknessHighlight: weaknessHighlight ?? this.weaknessHighlight,
      actionItems: actionItems ?? this.actionItems,
      rawSummary: rawSummary ?? this.rawSummary,
      saved: saved ?? this.saved,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  String toString() {
    return 'InterviewSessionData{companyName: $companyName, positionTitle: $positionTitle, status: $status, sessionId: $sessionId}';
  }
}
