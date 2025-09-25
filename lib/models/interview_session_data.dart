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

  // ===== LOADING STATES =====
  bool isStartingSession; // Loading state for session start
  String? error; // Error message if any

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

    // Loading states
    this.isStartingSession = false,
    this.error,

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

  // Mark as saved
  InterviewSessionData markAsSaved() {
    return copyWith(saved: true, savedAt: DateTime.now(), status: 'saved');
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
      isStartingSession: isStartingSession ?? this.isStartingSession,
      error: error ?? this.error,
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
