class JobListing {
  final int id;
  final String jobTitle;
  final String companyName;
  final String location;
  final String jobUrl;
  final String? postedDate;

  JobListing({
    required this.id,
    required this.jobTitle,
    required this.companyName,
    required this.location,
    required this.jobUrl,
    this.postedDate,
  });

  factory JobListing.fromJson(Map<String, dynamic> json) {
    return JobListing(
      id: json['id'] ?? 0,
      jobTitle: json['job_title'] ?? '',
      companyName: json['company_name'] ?? '',
      location: json['location'] ?? '',
      jobUrl: json['job_url'] ?? '',
      postedDate: json['posted_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_title': jobTitle,
      'company_name': companyName,
      'location': location,
      'job_url': jobUrl,
      'posted_date': postedDate,
    };
  }
}

class JobListingsState {
  final List<JobListing> jobs;
  final bool isLoading;
  final String? error;
  final Set<int> appliedJobIds;
  final Set<int> applyingJobIds;

  JobListingsState({
    this.jobs = const [],
    this.isLoading = false,
    this.error,
    this.appliedJobIds = const {},
    this.applyingJobIds = const {},
  });

  JobListingsState copyWith({
    List<JobListing>? jobs,
    bool? isLoading,
    String? error,
    Set<int>? appliedJobIds,
    Set<int>? applyingJobIds,
  }) {
    return JobListingsState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      appliedJobIds: appliedJobIds ?? this.appliedJobIds,
      applyingJobIds: applyingJobIds ?? this.applyingJobIds,
    );
  }
}
