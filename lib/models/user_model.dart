class UserWorkExperience {
  final int? id;
  final String? jobTitle;
  final String? companyName;
  final String? workStartDate;
  final String? workEndDate;
  final List<String>? keyResponsibilities;
  final bool? isCurrentJob;
  final String? createdAt;
  final String? updatedAt;

  UserWorkExperience({
    this.id,
    this.jobTitle,
    this.companyName,
    this.workStartDate,
    this.workEndDate,
    this.keyResponsibilities,
    this.isCurrentJob,
    this.createdAt,
    this.updatedAt,
  });

  factory UserWorkExperience.fromJson(Map<String, dynamic> json) {
    return UserWorkExperience(
      id: json['id'],
      jobTitle: json['job_title'],
      companyName: json['company_name'],
      workStartDate: json['work_start_date'],
      workEndDate: json['work_end_date'],
      keyResponsibilities: json['key_responsibilities'] != null
          ? List<String>.from(json['key_responsibilities'])
          : null,
      isCurrentJob: json['is_current_job'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_title': jobTitle,
      'company_name': companyName,
      'work_start_date': workStartDate,
      'work_end_date': workEndDate,
      'key_responsibilities': keyResponsibilities,
      'is_current_job': isCurrentJob,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class User {
  User({
    int? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? fullName,
    String? phoneNumber,
    String? dateOfBirth,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? professionalSummary,
    String? linkedinUrl,
    String? githubUrl,
    String? portfolioUrl,
    List<String>? desiredJobTitles,
    List<String>? industryPreferences,
    List<String>? longTermCareerGoals,
    int? degreeType,
    int? major,
    int? institution,
    String? graduationDate,
    int? certificationsTraining,
    List<UserWorkExperience>? workExperience,
    List<String>? hardSkills,
    List<String>? softSkills,
    List<String>? toolsTechnologies,
    List<String>? languages,
    List<String>? volunteerWork,
    List<String>? hobbiesInterests,
    String? references,
    dynamic profileImage,
    bool? isProfileComplete,
    int? role,
    int? signupProgress,
    dynamic resumeFileName,
    int? desiredPayRange,
    dynamic locationPreferences,
    String? createdAt,
    String? updatedAt,
    int? profileCompletionPercentage,
    String? workStartDate,
    String? workEndDate,
  }) {
    _id = id;
    _email = email;
    _username = username;
    _firstName = firstName;
    _lastName = lastName;
    _fullName = fullName;
    _phoneNumber = phoneNumber;
    _dateOfBirth = dateOfBirth;
    _address = address;
    _city = city;
    _state = state;
    _country = country;
    _postalCode = postalCode;
    _professionalSummary = professionalSummary;
    _linkedinUrl = linkedinUrl;
    _githubUrl = githubUrl;
    _portfolioUrl = portfolioUrl;
    _desiredJobTitles = desiredJobTitles;
    _industryPreferences = industryPreferences;
    _longTermCareerGoals = longTermCareerGoals;
    _degreeType = degreeType;
    _major = major;
    _institution = institution;
    _graduationDate = graduationDate;
    _certificationsTraining = certificationsTraining;
    _workExperience = workExperience;
    _hardSkills = hardSkills;
    _softSkills = softSkills;
    _toolsTechnologies = toolsTechnologies;
    _languages = languages;
    _volunteerWork = volunteerWork;
    _hobbiesInterests = hobbiesInterests;
    _references = references;
    _profileImage = profileImage;
    _isProfileComplete = isProfileComplete;
    _role = role;
    _signupProgress = signupProgress;
    _resumeFileName = resumeFileName;
    _desiredPayRange = desiredPayRange;
    _locationPreferences = locationPreferences;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _profileCompletionPercentage = profileCompletionPercentage;
    _workStartDate = workStartDate;
    _workEndDate = workEndDate;
  }

  User.fromJson(dynamic json) {
    _id = json['id'];
    _email = json['email'];
    _username = json['username'];
    _firstName = json['first_name'];
    _lastName = json['last_name'];
    _fullName = json['full_name'];
    _phoneNumber = json['phone_number'];
    _dateOfBirth = json['date_of_birth'];
    _address = json['address'];
    _city = json['city'];
    _state = json['state'];
    _country = json['country'];
    _postalCode = json['postal_code'];
    _professionalSummary = json['professional_summary'];
    _linkedinUrl = json['linkedin_url'];
    _githubUrl = json['github_url'];
    _portfolioUrl = json['portfolio_url'];
    _desiredJobTitles = json['desired_job_titles'] != null
        ? List<String>.from(json['desired_job_titles'])
        : null;
    _industryPreferences = json['industry_preferences'] != null
        ? List<String>.from(json['industry_preferences'])
        : null;
    _longTermCareerGoals = json['long_term_career_goals'] != null
        ? List<String>.from(json['long_term_career_goals'])
        : null;
    _degreeType = json['degree_type'];
    _major = json['major'];
    _institution = json['institution'];
    _graduationDate = json['graduation_date'];
    _certificationsTraining = json['certifications_training'];
    _workExperience = json['work_experience'] != null
        ? (json['work_experience'] as List)
              .map((e) => UserWorkExperience.fromJson(e))
              .toList()
        : null;
    _hardSkills = json['hard_skills'] != null
        ? List<String>.from(json['hard_skills'])
        : null;
    _softSkills = json['soft_skills'] != null
        ? List<String>.from(json['soft_skills'])
        : null;
    _toolsTechnologies = json['tools_technologies'] != null
        ? List<String>.from(json['tools_technologies'])
        : null;
    _languages = json['languages'] != null
        ? List<String>.from(json['languages'])
        : null;
    _volunteerWork = json['volunteer_work'] != null
        ? List<String>.from(json['volunteer_work'])
        : null;
    _hobbiesInterests = json['hobbies_interests'] != null
        ? List<String>.from(json['hobbies_interests'])
        : null;
    _references = json['references'];
    _profileImage = json['profile_image'];
    _isProfileComplete = json['is_profile_complete'];
    _role = json['role'];
    _signupProgress = json['signup_progress'];
    _resumeFileName = json['resume_file_name'];
    _desiredPayRange = json['desired_pay_range'];
    _locationPreferences = json['location_preferences'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _profileCompletionPercentage = json['profile_completion_percentage'];
    _workStartDate = json['work_start_date'];
    _workEndDate = json['work_end_date'];
  }

  int? _id;
  String? _email;
  String? _username;
  String? _firstName;
  String? _lastName;
  String? _fullName;
  String? _phoneNumber;
  String? _dateOfBirth;
  String? _address;
  String? _city;
  String? _state;
  String? _country;
  String? _postalCode;
  String? _professionalSummary;
  String? _linkedinUrl;
  String? _githubUrl;
  String? _portfolioUrl;
  List<String>? _desiredJobTitles;
  List<String>? _industryPreferences;
  List<String>? _longTermCareerGoals;
  int? _degreeType;
  int? _major;
  int? _institution;
  String? _graduationDate;
  int? _certificationsTraining;
  List<UserWorkExperience>? _workExperience;
  List<String>? _hardSkills;
  List<String>? _softSkills;
  List<String>? _toolsTechnologies;
  List<String>? _languages;
  List<String>? _volunteerWork;
  List<String>? _hobbiesInterests;
  String? _references;
  dynamic _profileImage;
  bool? _isProfileComplete;
  int? _role;
  int? _signupProgress;
  dynamic _resumeFileName;
  int? _desiredPayRange;
  dynamic _locationPreferences;
  String? _createdAt;
  String? _updatedAt;
  int? _profileCompletionPercentage;
  String? _workStartDate;
  String? _workEndDate;

  int? get id => _id;

  String? get email => _email;

  String? get username => _username;

  String? get firstName => _firstName;

  String? get lastName => _lastName;

  String? get fullName => _fullName;

  String? get phoneNumber => _phoneNumber;

  String? get dateOfBirth => _dateOfBirth;

  String? get address => _address;

  String? get city => _city;

  String? get state => _state;

  String? get country => _country;

  String? get postalCode => _postalCode;

  String? get professionalSummary => _professionalSummary;

  String? get linkedinUrl => _linkedinUrl;

  String? get githubUrl => _githubUrl;

  String? get portfolioUrl => _portfolioUrl;

  List<String>? get desiredJobTitles => _desiredJobTitles;

  List<String>? get industryPreferences => _industryPreferences;

  List<String>? get longTermCareerGoals => _longTermCareerGoals;

  int? get degreeType => _degreeType;

  int? get major => _major;

  int? get institution => _institution;

  String? get graduationDate => _graduationDate;

  int? get certificationsTraining => _certificationsTraining;

  List<UserWorkExperience>? get workExperience => _workExperience;

  List<String>? get hardSkills => _hardSkills;

  List<String>? get softSkills => _softSkills;

  List<String>? get toolsTechnologies => _toolsTechnologies;

  List<String>? get languages => _languages;

  List<String>? get volunteerWork => _volunteerWork;

  List<String>? get hobbiesInterests => _hobbiesInterests;

  String? get references => _references;

  dynamic get profileImage => _profileImage;

  bool? get isProfileComplete => _isProfileComplete;

  int? get role => _role;

  int? get signupProgress => _signupProgress;

  dynamic get resumeFileName => _resumeFileName;

  int? get desiredPayRange => _desiredPayRange;

  dynamic get locationPreferences => _locationPreferences;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  int? get profileCompletionPercentage => _profileCompletionPercentage;

  String? get workStartDate => _workStartDate;

  String? get workEndDate => _workEndDate;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['email'] = _email;
    map['username'] = _username;
    map['first_name'] = _firstName;
    map['last_name'] = _lastName;
    map['full_name'] = _fullName;
    map['phone_number'] = _phoneNumber;
    map['date_of_birth'] = _dateOfBirth;
    map['address'] = _address;
    map['city'] = _city;
    map['state'] = _state;
    map['country'] = _country;
    map['postal_code'] = _postalCode;
    map['professional_summary'] = _professionalSummary;
    map['linkedin_url'] = _linkedinUrl;
    map['github_url'] = _githubUrl;
    map['portfolio_url'] = _portfolioUrl;
    map['desired_job_titles'] = _desiredJobTitles;
    map['industry_preferences'] = _industryPreferences;
    map['long_term_career_goals'] = _longTermCareerGoals;
    map['degree_type'] = _degreeType;
    map['major'] = _major;
    map['institution'] = _institution;
    map['graduation_date'] = _graduationDate;
    map['certifications_training'] = _certificationsTraining;
    if (_workExperience != null) {
      map['work_experience'] = _workExperience!.map((e) => e.toJson()).toList();
    }
    map['hard_skills'] = _hardSkills;
    map['soft_skills'] = _softSkills;
    map['tools_technologies'] = _toolsTechnologies;
    map['languages'] = _languages;
    map['volunteer_work'] = _volunteerWork;
    map['hobbies_interests'] = _hobbiesInterests;
    map['references'] = _references;
    map['profile_image'] = _profileImage;
    map['is_profile_complete'] = _isProfileComplete;
    map['role'] = _role;
    map['signup_progress'] = _signupProgress;
    map['resume_file_name'] = _resumeFileName;
    map['desired_pay_range'] = _desiredPayRange;
    map['location_preferences'] = _locationPreferences;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    map['profile_completion_percentage'] = _profileCompletionPercentage;
    map['work_start_date'] = _workStartDate;
    map['work_end_date'] = _workEndDate;
    return map;
  }
}
