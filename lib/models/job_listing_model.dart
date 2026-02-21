class JobListing {
  final int id;
  final String jobTitle;
  final String companyName;
  final String location;
  final String jobUrl;
  final String? postedDate;
  final String? employerLogo;
  final String? employerWebsite;
  final String? description;
  final JobHighlights? jobHighlights;
  final String? jobCity;
  final String? jobState;
  final String? jobCountry;
  final String? employmentType;
  final bool isRemote;
  final double? salaryMin;
  final double? salaryMax;
  final String? salaryCurrency;
  final String? salaryPeriod;
  final bool isDirectApply;
  final bool hasApplied;

  JobListing({
    required this.id,
    required this.jobTitle,
    required this.companyName,
    required this.location,
    required this.jobUrl,
    this.postedDate,
    this.employerLogo,
    this.employerWebsite,
    this.description,
    this.jobHighlights,
    this.jobCity,
    this.jobState,
    this.jobCountry,
    this.employmentType,
    this.isRemote = false,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency,
    this.salaryPeriod,
    this.isDirectApply = false,
    this.hasApplied = false,
  });

  factory JobListing.fromJson(Map<String, dynamic> json) {
    return JobListing(
      id: json['id'] ?? 0,
      jobTitle: json['title'] ?? '',
      companyName: json['company_name'] ?? '',
      location: json['job_location'] ?? '',
      jobUrl: json['apply_link'] ?? '',
      postedDate: json['posted_date'],
      employerLogo: json['employer_logo'],
      employerWebsite: json['employer_website'],
      description: json['description'],
      jobHighlights: json['job_highlights'] != null
          ? JobHighlights.fromJson(json['job_highlights'])
          : null,
      jobCity: json['job_city'],
      jobState: json['job_state'],
      jobCountry: json['job_country'],
      employmentType: json['employment_type'],
      isRemote: json['is_remote'] ?? false,
      salaryMin: (json['salary_min'] as num?)?.toDouble(),
      salaryMax: (json['salary_max'] as num?)?.toDouble(),
      salaryCurrency: json['salary_currency'],
      salaryPeriod: json['salary_period'],
      isDirectApply: json['is_direct_apply'] ?? false,
      hasApplied: json['has_applied'] ?? false,
    );
  }

  String get salaryRange {
    if (salaryMin == null && salaryMax == null) return '';
    final currency = salaryCurrency ?? 'USD';
    if (salaryMin != null && salaryMax != null) {
      return '\$${_formatSalary(salaryMin!)} - \$${_formatSalary(salaryMax!)} $currency';
    }
    if (salaryMin != null) {
      return 'From \$${_formatSalary(salaryMin!)} $currency';
    }
    return 'Up to \$${_formatSalary(salaryMax!)} $currency';
  }

  String _formatSalary(double value) {
    if (value >= 1000) {
      final k = value / 1000;
      return k == k.roundToDouble()
          ? '${k.toInt()}k'
          : '${k.toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

class JobHighlights {
  final List<String> qualifications;
  final List<String> benefits;
  final List<String> responsibilities;

  JobHighlights({
    this.qualifications = const [],
    this.benefits = const [],
    this.responsibilities = const [],
  });

  factory JobHighlights.fromJson(Map<String, dynamic> json) {
    return JobHighlights(
      qualifications: json['Qualifications'] != null
          ? List<String>.from(json['Qualifications'])
          : [],
      benefits: json['Benefits'] != null
          ? List<String>.from(json['Benefits'])
          : [],
      responsibilities: json['Responsibilities'] != null
          ? List<String>.from(json['Responsibilities'])
          : [],
    );
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
