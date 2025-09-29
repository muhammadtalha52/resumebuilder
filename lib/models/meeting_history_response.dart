class MeetingHistoryResponse {
  final String? status;
  final String? message;
  final List<MeetingHistoryItem>? data;

  MeetingHistoryResponse({this.status, this.message, this.data});

  factory MeetingHistoryResponse.fromJson(Map<String, dynamic> json) {
    return MeetingHistoryResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? (json['data'] as List)
                .map((item) => MeetingHistoryItem.fromJson(item))
                .toList()
          : null,
    );
  }
}

class MeetingHistoryItem {
  final int id;
  final int? user;
  final String? userEmail;
  final String? userFullName;
  final String? companyName;
  final String? positionTitle;
  final String? interviewType;
  final String? roleIndustry;
  final String? jobDescription;
  final String? languageSelector;
  final String? transcript;
  final String? status;
  final String? interviewDate;
  final int? durationMinutes;
  final String? location;
  final String? interviewerName;
  final String? interviewerEmail;
  final String? notes;
  final String? feedback;
  final String? result;
  final List<String>? keyTopics;
  final List<String>? strengthHighlight;
  final List<String>? weaknessHighlight;
  final List<String>? actionItems;
  final List<String>? decisionsMade;
  final List<String>? topMomentsInInterview;
  final List<String>? aiDrivenInterviewAnalytics;
  final List<String>? areasOfImprovement;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MeetingHistoryItem({
    required this.id,
    this.user,
    this.userEmail,
    this.userFullName,
    this.companyName,
    this.positionTitle,
    this.interviewType,
    this.roleIndustry,
    this.jobDescription,
    this.languageSelector,
    this.transcript,
    this.status,
    this.interviewDate,
    this.durationMinutes,
    this.location,
    this.interviewerName,
    this.interviewerEmail,
    this.notes,
    this.feedback,
    this.result,
    this.keyTopics,
    this.strengthHighlight,
    this.weaknessHighlight,
    this.actionItems,
    this.decisionsMade,
    this.topMomentsInInterview,
    this.aiDrivenInterviewAnalytics,
    this.areasOfImprovement,
    this.createdAt,
    this.updatedAt,
  });

  factory MeetingHistoryItem.fromJson(Map<String, dynamic> json) {
    return MeetingHistoryItem(
      id: json['id'] ?? 0,
      user: json['user'],
      userEmail: json['user_email'],
      userFullName: json['user_full_name'],
      companyName: json['company_name'],
      positionTitle: json['position_title'],
      interviewType: json['interview_type'],
      roleIndustry: json['role_industry'],
      jobDescription: json['job_description'],
      languageSelector: json['language_selector'],
      transcript: json['transcript'],
      status: json['status'],
      interviewDate: json['interview_date'],
      durationMinutes: json['duration_minutes'],
      location: json['location'],
      interviewerName: json['interviewer_name'],
      interviewerEmail: json['interviewer_email'],
      notes: json['notes'],
      feedback: json['feedback'],
      result: json['result'],
      keyTopics: json['key_topics'] != null
          ? List<String>.from(json['key_topics'])
          : null,
      strengthHighlight: json['strength_highlight'] != null
          ? List<String>.from(json['strength_highlight'])
          : null,
      weaknessHighlight: json['weakness_highlight'] != null
          ? List<String>.from(json['weakness_highlight'])
          : null,
      actionItems: json['action_items'] != null
          ? List<String>.from(json['action_items'])
          : null,
      decisionsMade: json['decisions_made'] != null
          ? List<String>.from(json['decisions_made'])
          : null,
      topMomentsInInterview: json['top_moments_in_interview'] != null
          ? List<String>.from(json['top_moments_in_interview'])
          : null,
      aiDrivenInterviewAnalytics: json['ai_driven_interview_analytics'] != null
          ? List<String>.from(json['ai_driven_interview_analytics'])
          : null,
      areasOfImprovement: json['areas_of_improvement'] != null
          ? List<String>.from(json['areas_of_improvement'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  bool get isInterview => interviewType?.toLowerCase() == 'interview';
  bool get isMeeting => interviewType?.toLowerCase() == 'meeting';
}
