class DesiredJobTitle {
  final int? id;
  final String? title;
  final String? createdAt;

  DesiredJobTitle({this.id, this.title, this.createdAt});

  factory DesiredJobTitle.fromJson(Map<String, dynamic> json) {
    return DesiredJobTitle(
      id: json['id'],
      title: json['title'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'created_at': createdAt};
  }
}

class IdealJobTitle {
  final int? id;
  final String? title;
  final String? createdAt;

  IdealJobTitle({this.id, this.title, this.createdAt});

  factory IdealJobTitle.fromJson(Map<String, dynamic> json) {
    return IdealJobTitle(
      id: json['id'],
      title: json['title'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'created_at': createdAt};
  }
}

class IndustryPreference {
  final int? id;
  final String? industry;
  final String? createdAt;

  IndustryPreference({this.id, this.industry, this.createdAt});

  factory IndustryPreference.fromJson(Map<String, dynamic> json) {
    return IndustryPreference(
      id: json['id'],
      industry: json['industry'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'industry': industry, 'created_at': createdAt};
  }
}

class CareerGoal {
  final int? id;
  final String? goal;
  final String? createdAt;

  CareerGoal({this.id, this.goal, this.createdAt});

  factory CareerGoal.fromJson(Map<String, dynamic> json) {
    return CareerGoal(
      id: json['id'],
      goal: json['goal'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'goal': goal, 'created_at': createdAt};
  }
}

class HardSkill {
  final int? id;
  final String? skill;
  final String? proficiencyLevel;
  final String? createdAt;

  HardSkill({this.id, this.skill, this.proficiencyLevel, this.createdAt});

  factory HardSkill.fromJson(Map<String, dynamic> json) {
    return HardSkill(
      id: json['id'],
      skill: json['skill'],
      proficiencyLevel: json['proficiency_level'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skill': skill,
      'proficiency_level': proficiencyLevel,
      'created_at': createdAt,
    };
  }
}

class SoftSkill {
  final int? id;
  final String? skill;
  final String? proficiencyLevel;
  final String? createdAt;

  SoftSkill({this.id, this.skill, this.proficiencyLevel, this.createdAt});

  factory SoftSkill.fromJson(Map<String, dynamic> json) {
    return SoftSkill(
      id: json['id'],
      skill: json['skill'],
      proficiencyLevel: json['proficiency_level'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skill': skill,
      'proficiency_level': proficiencyLevel,
      'created_at': createdAt,
    };
  }
}

class ToolTechnology {
  final int? id;
  final String? tool;
  final String? proficiencyLevel;
  final int? yearsExperience;
  final String? createdAt;

  ToolTechnology({
    this.id,
    this.tool,
    this.proficiencyLevel,
    this.yearsExperience,
    this.createdAt,
  });

  factory ToolTechnology.fromJson(Map<String, dynamic> json) {
    return ToolTechnology(
      id: json['id'],
      tool: json['tool'],
      proficiencyLevel: json['proficiency_level'],
      yearsExperience: json['years_experience'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tool': tool,
      'proficiency_level': proficiencyLevel,
      'years_experience': yearsExperience,
      'created_at': createdAt,
    };
  }
}

class Language {
  final int? id;
  final String? language;
  final String? proficiencyLevel;
  final bool? isNative;
  final String? createdAt;

  Language({
    this.id,
    this.language,
    this.proficiencyLevel,
    this.isNative,
    this.createdAt,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'],
      language: json['language'],
      proficiencyLevel: json['proficiency_level'],
      isNative: json['is_native'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language': language,
      'proficiency_level': proficiencyLevel,
      'is_native': isNative,
      'created_at': createdAt,
    };
  }
}

class VolunteerWork {
  final int? id;
  final String? organization;
  final String? role;
  final String? description;
  final String? startDate;
  final String? endDate;
  final bool? isCurrent;
  final String? createdAt;

  VolunteerWork({
    this.id,
    this.organization,
    this.role,
    this.description,
    this.startDate,
    this.endDate,
    this.isCurrent,
    this.createdAt,
  });

  factory VolunteerWork.fromJson(Map<String, dynamic> json) {
    return VolunteerWork(
      id: json['id'],
      organization: json['organization'],
      role: json['role'] ?? 2,
      description: json['description'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      isCurrent: json['is_current'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization': organization,
      'role': role,
      'description': description,
      'start_date': startDate,
      'end_date': endDate,
      'is_current': isCurrent,
      'created_at': createdAt,
    };
  }
}

class HobbyInterest {
  final int? id;
  final String? hobbyInterest;
  final String? category;
  final String? createdAt;

  HobbyInterest({this.id, this.hobbyInterest, this.category, this.createdAt});

  factory HobbyInterest.fromJson(Map<String, dynamic> json) {
    return HobbyInterest(
      id: json['id'],
      hobbyInterest: json['hobby_interest'],
      category: json['category'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hobby_interest': hobbyInterest,
      'category': category,
      'created_at': createdAt,
    };
  }
}

class LocationPreference {
  final int? id;
  final String? location;
  final String? locationType;
  final bool? isRemoteOk;
  final String? createdAt;

  LocationPreference({
    this.id,
    this.location,
    this.locationType,
    this.isRemoteOk,
    this.createdAt,
  });

  factory LocationPreference.fromJson(Map<String, dynamic> json) {
    return LocationPreference(
      id: json['id'],
      location: json['location'],
      locationType: json['location_type'],
      isRemoteOk: json['is_remote_ok'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'location_type': locationType,
      'is_remote_ok': isRemoteOk,
      'created_at': createdAt,
    };
  }
}

class CertificationTraining {
  final int? id;
  final String? name;
  final String? createdAt;

  CertificationTraining({this.id, this.name, this.createdAt});

  factory CertificationTraining.fromJson(Map<String, dynamic> json) {
    return CertificationTraining(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'created_at': createdAt};
  }
}

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
    List<DesiredJobTitle>? desiredJobTitles,
    List<IndustryPreference>? industryPreferences,
    List<CareerGoal>? careerGoals,
    int? degreeType,
    int? major,
    int? institution,
    String? graduationDate,
    List<CertificationTraining>? certificationsTraining,
    List<UserWorkExperience>? workExperience,
    List<HardSkill>? hardSkills,
    List<SoftSkill>? softSkills,
    List<ToolTechnology>? toolsTechnologies,
    List<Language>? languages,
    List<VolunteerWork>? volunteerWork,
    List<HobbyInterest>? hobbiesInterests,
    String? references,
    dynamic profileImage,
    bool? isProfileComplete,
    int? role,
    int? signupProgress,
    dynamic resumeFileName,
    int? desiredPayRange,
    List<LocationPreference>? locationPreferences,
    String? createdAt,
    String? updatedAt,
    int? profileCompletionPercentage,
    String? workStartDate,
    String? workEndDate,
    String? homeTown,
    String? schoolName,
    String? schoolMajor,
    String? schoolGraduationDate,
    List<IdealJobTitle>? idealJobTitles,
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
    _careerGoals = careerGoals;
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
    _homeTown = homeTown;
    _schoolName = schoolName;
    _schoolMajor = schoolMajor;
    _schoolGraduationDate = schoolGraduationDate;
    _idealJobTitles = idealJobTitles;
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
        ? (json['desired_job_titles'] as List)
              .map((e) => DesiredJobTitle.fromJson(e))
              .toList()
        : null;
    _industryPreferences = json['industry_preferences'] != null
        ? (json['industry_preferences'] as List)
              .map((e) => IndustryPreference.fromJson(e))
              .toList()
        : null;
    _careerGoals = json['career_goals'] != null
        ? (json['career_goals'] as List)
              .map((e) => CareerGoal.fromJson(e))
              .toList()
        : null;
    _degreeType = json['degree_type'];
    _major = json['major'];
    _institution = json['institution'];
    _graduationDate = json['graduation_date'];
    _certificationsTraining = json['certifications_training'] != null
        ? (json['certifications_training'] as List)
              .map((e) => CertificationTraining.fromJson(e))
              .toList()
        : null;
    _workExperience = json['work_experience'] != null
        ? (json['work_experience'] as List)
              .map((e) => UserWorkExperience.fromJson(e))
              .toList()
        : null;
    _hardSkills = json['hard_skills'] != null
        ? (json['hard_skills'] as List)
              .map((e) => HardSkill.fromJson(e))
              .toList()
        : null;
    _softSkills = json['soft_skills'] != null
        ? (json['soft_skills'] as List)
              .map((e) => SoftSkill.fromJson(e))
              .toList()
        : null;
    _toolsTechnologies = json['tools_technologies'] != null
        ? (json['tools_technologies'] as List)
              .map((e) => ToolTechnology.fromJson(e))
              .toList()
        : null;
    _languages = json['languages'] != null
        ? (json['languages'] as List).map((e) => Language.fromJson(e)).toList()
        : null;
    _volunteerWork = json['volunteer_work'] != null
        ? (json['volunteer_work'] as List)
              .map((e) => VolunteerWork.fromJson(e))
              .toList()
        : null;
    _hobbiesInterests = json['hobbies_interests'] != null
        ? (json['hobbies_interests'] as List)
              .map((e) => HobbyInterest.fromJson(e))
              .toList()
        : null;
    _references = json['references'];
    _profileImage = json['profile_image'];
    _isProfileComplete = json['is_profile_complete'];
    _role = json['role'];
    _signupProgress = json['signup_progress'];
    _resumeFileName = json['resume_file_name'];
    _desiredPayRange = json['desired_pay_range'];
    _locationPreferences = json['location_preferences'] != null
        ? (json['location_preferences'] as List)
              .map((e) => LocationPreference.fromJson(e))
              .toList()
        : null;
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _profileCompletionPercentage = json['profile_completion_percentage'];
    _workStartDate = json['work_start_date'];
    _workEndDate = json['work_end_date'];
    _homeTown = json['home_town'];
    _schoolName = json['school_name'];
    _schoolMajor = json['school_major'];
    _schoolGraduationDate = json['school_graduation_date'];
    _idealJobTitles = json['ideal_job_titles'] != null
        ? (json['ideal_job_titles'] as List)
              .map((e) => IdealJobTitle.fromJson(e))
              .toList()
        : null;
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
  List<DesiredJobTitle>? _desiredJobTitles;
  List<IndustryPreference>? _industryPreferences;
  List<CareerGoal>? _careerGoals;
  int? _degreeType;
  int? _major;
  int? _institution;
  String? _graduationDate;
  List<CertificationTraining>? _certificationsTraining;
  List<UserWorkExperience>? _workExperience;
  List<HardSkill>? _hardSkills;
  List<SoftSkill>? _softSkills;
  List<ToolTechnology>? _toolsTechnologies;
  List<Language>? _languages;
  List<VolunteerWork>? _volunteerWork;
  List<HobbyInterest>? _hobbiesInterests;
  String? _references;
  dynamic _profileImage;
  bool? _isProfileComplete;
  int? _role;
  int? _signupProgress;
  dynamic _resumeFileName;
  int? _desiredPayRange;
  List<LocationPreference>? _locationPreferences;
  String? _createdAt;
  String? _updatedAt;
  int? _profileCompletionPercentage;
  String? _workStartDate;
  String? _workEndDate;
  String? _homeTown;
  String? _schoolName;
  String? _schoolMajor;
  String? _schoolGraduationDate;
  List<IdealJobTitle>? _idealJobTitles;

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

  List<DesiredJobTitle>? get desiredJobTitles => _desiredJobTitles;

  List<IndustryPreference>? get industryPreferences => _industryPreferences;

  List<CareerGoal>? get careerGoals => _careerGoals;

  int? get degreeType => _degreeType;

  int? get major => _major;

  int? get institution => _institution;

  String? get graduationDate => _graduationDate;

  List<CertificationTraining>? get certificationsTraining =>
      _certificationsTraining;

  List<UserWorkExperience>? get workExperience => _workExperience;

  List<HardSkill>? get hardSkills => _hardSkills;

  List<SoftSkill>? get softSkills => _softSkills;

  List<ToolTechnology>? get toolsTechnologies => _toolsTechnologies;

  List<Language>? get languages => _languages;

  List<VolunteerWork>? get volunteerWork => _volunteerWork;

  List<HobbyInterest>? get hobbiesInterests => _hobbiesInterests;

  String? get references => _references;

  dynamic get profileImage => _profileImage;

  bool? get isProfileComplete => _isProfileComplete;

  int? get role => _role;

  int? get signupProgress => _signupProgress;

  dynamic get resumeFileName => _resumeFileName;

  int? get desiredPayRange => _desiredPayRange;

  List<LocationPreference>? get locationPreferences => _locationPreferences;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  int? get profileCompletionPercentage => _profileCompletionPercentage;

  String? get workStartDate => _workStartDate;

  String? get workEndDate => _workEndDate;

  String? get homeTown => _homeTown;

  String? get schoolName => _schoolName;

  String? get schoolMajor => _schoolMajor;

  String? get schoolGraduationDate => _schoolGraduationDate;

  List<IdealJobTitle>? get idealJobTitles => _idealJobTitles;

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
    if (_desiredJobTitles != null) {
      map['desired_job_titles'] = _desiredJobTitles!
          .map((e) => e.toJson())
          .toList();
    }
    if (_industryPreferences != null) {
      map['industry_preferences'] = _industryPreferences!
          .map((e) => e.toJson())
          .toList();
    }
    if (_careerGoals != null) {
      map['career_goals'] = _careerGoals!.map((e) => e.toJson()).toList();
    }
    map['degree_type'] = _degreeType;
    map['major'] = _major;
    map['institution'] = _institution;
    map['graduation_date'] = _graduationDate;
    if (_certificationsTraining != null) {
      map['certifications_training'] = _certificationsTraining!
          .map((e) => e.toJson())
          .toList();
    }
    if (_workExperience != null) {
      map['work_experience'] = _workExperience!.map((e) => e.toJson()).toList();
    }
    if (_hardSkills != null) {
      map['hard_skills'] = _hardSkills!.map((e) => e.toJson()).toList();
    }
    if (_softSkills != null) {
      map['soft_skills'] = _softSkills!.map((e) => e.toJson()).toList();
    }
    if (_toolsTechnologies != null) {
      map['tools_technologies'] = _toolsTechnologies!
          .map((e) => e.toJson())
          .toList();
    }
    if (_languages != null) {
      map['languages'] = _languages!.map((e) => e.toJson()).toList();
    }
    if (_volunteerWork != null) {
      map['volunteer_work'] = _volunteerWork!.map((e) => e.toJson()).toList();
    }
    if (_hobbiesInterests != null) {
      map['hobbies_interests'] = _hobbiesInterests!
          .map((e) => e.toJson())
          .toList();
    }
    map['references'] = _references;
    map['profile_image'] = _profileImage;
    map['is_profile_complete'] = _isProfileComplete;
    map['role'] = _role;
    map['signup_progress'] = _signupProgress;
    map['resume_file_name'] = _resumeFileName;
    map['desired_pay_range'] = _desiredPayRange;
    if (_locationPreferences != null) {
      map['location_preferences'] = _locationPreferences!
          .map((e) => e.toJson())
          .toList();
    }
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    map['profile_completion_percentage'] = _profileCompletionPercentage;
    map['work_start_date'] = _workStartDate;
    map['work_end_date'] = _workEndDate;
    map['home_town'] = _homeTown;
    map['school_name'] = _schoolName;
    map['school_major'] = _schoolMajor;
    map['school_graduation_date'] = _schoolGraduationDate;
    if (_idealJobTitles != null) {
      map['ideal_job_titles'] = _idealJobTitles!
          .map((e) => e.toJson())
          .toList();
    }
    return map;
  }

  User copyWith({
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
    List<DesiredJobTitle>? desiredJobTitles,
    List<IndustryPreference>? industryPreferences,
    List<CareerGoal>? careerGoals,
    int? degreeType,
    int? major,
    int? institution,
    String? graduationDate,
    List<CertificationTraining>? certificationsTraining,
    List<UserWorkExperience>? workExperience,
    List<HardSkill>? hardSkills,
    List<SoftSkill>? softSkills,
    List<ToolTechnology>? toolsTechnologies,
    List<Language>? languages,
    List<VolunteerWork>? volunteerWork,
    List<HobbyInterest>? hobbiesInterests,
    String? references,
    dynamic profileImage,
    bool? isProfileComplete,
    int? role,
    int? signupProgress,
    dynamic resumeFileName,
    int? desiredPayRange,
    List<LocationPreference>? locationPreferences,
    String? createdAt,
    String? updatedAt,
    int? profileCompletionPercentage,
    String? workStartDate,
    String? workEndDate,
    String? homeTown,
    String? schoolName,
    String? schoolMajor,
    String? schoolGraduationDate,
    List<IdealJobTitle>? idealJobTitles,
  }) {
    return User(
      id: id ?? _id,
      email: email ?? _email,
      username: username ?? _username,
      firstName: firstName ?? _firstName,
      lastName: lastName ?? _lastName,
      fullName: fullName ?? _fullName,
      phoneNumber: phoneNumber ?? _phoneNumber,
      dateOfBirth: dateOfBirth ?? _dateOfBirth,
      address: address ?? _address,
      city: city ?? _city,
      state: state ?? _state,
      country: country ?? _country,
      postalCode: postalCode ?? _postalCode,
      professionalSummary: professionalSummary ?? _professionalSummary,
      linkedinUrl: linkedinUrl ?? _linkedinUrl,
      githubUrl: githubUrl ?? _githubUrl,
      portfolioUrl: portfolioUrl ?? _portfolioUrl,
      desiredJobTitles: desiredJobTitles ?? _desiredJobTitles,
      industryPreferences: industryPreferences ?? _industryPreferences,
      careerGoals: careerGoals ?? _careerGoals,
      degreeType: degreeType ?? _degreeType,
      major: major ?? _major,
      institution: institution ?? _institution,
      graduationDate: graduationDate ?? _graduationDate,
      certificationsTraining: certificationsTraining ?? _certificationsTraining,
      workExperience: workExperience ?? _workExperience,
      hardSkills: hardSkills ?? _hardSkills,
      softSkills: softSkills ?? _softSkills,
      toolsTechnologies: toolsTechnologies ?? _toolsTechnologies,
      languages: languages ?? _languages,
      volunteerWork: volunteerWork ?? _volunteerWork,
      hobbiesInterests: hobbiesInterests ?? _hobbiesInterests,
      references: references ?? _references,
      profileImage: profileImage ?? _profileImage,
      isProfileComplete: isProfileComplete ?? _isProfileComplete,
      role: role ?? _role,
      signupProgress: signupProgress ?? _signupProgress,
      resumeFileName: resumeFileName ?? _resumeFileName,
      desiredPayRange: desiredPayRange ?? _desiredPayRange,
      locationPreferences: locationPreferences ?? _locationPreferences,
      createdAt: createdAt ?? _createdAt,
      updatedAt: updatedAt ?? _updatedAt,
      profileCompletionPercentage:
          profileCompletionPercentage ?? _profileCompletionPercentage,
      workStartDate: workStartDate ?? _workStartDate,
      workEndDate: workEndDate ?? _workEndDate,
      homeTown: homeTown ?? _homeTown,
      schoolName: schoolName ?? _schoolName,
      schoolMajor: schoolMajor ?? _schoolMajor,
      schoolGraduationDate: schoolGraduationDate ?? _schoolGraduationDate,
      idealJobTitles: idealJobTitles ?? _idealJobTitles,
    );
  }
}
