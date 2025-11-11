class UsageAllocation {
  final int id;
  final int userId;
  final String userEmail;
  final String userFullName;
  final int remainingResumeCount;
  final int remainingInterviewCount;
  final int remainingQuizCount;
  final int remainingDocumentUploadCount;
  final DateTime lastUpdated;

  UsageAllocation({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userFullName,
    required this.remainingResumeCount,
    required this.remainingInterviewCount,
    required this.remainingQuizCount,
    required this.remainingDocumentUploadCount,
    required this.lastUpdated,
  });

  factory UsageAllocation.fromJson(Map<String, dynamic> json) {
    return UsageAllocation(
      id: json['id'] as int,
      userId: json['user'] as int,
      userEmail: json['user_email'] as String,
      userFullName: json['user_full_name'] as String,
      remainingResumeCount: json['remaining_resume_count'] as int,
      remainingInterviewCount: json['remaining_interview_count'] as int,
      remainingQuizCount: json['remaining_quiz_count'] as int,
      remainingDocumentUploadCount:
          json['remaining_document_upload_count'] as int,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'user_email': userEmail,
      'user_full_name': userFullName,
      'remaining_resume_count': remainingResumeCount,
      'remaining_interview_count': remainingInterviewCount,
      'remaining_quiz_count': remainingQuizCount,
      'remaining_document_upload_count': remainingDocumentUploadCount,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
