class GenerateResumeResponse {
  GenerateResumeResponse({
    ResumeData? resumeData,
    String? pdfBase64,
    List<String>? regeneratedSections,
  }) {
    _resumeData = resumeData;
    _pdfBase64 = pdfBase64;
    _regeneratedSections = regeneratedSections;
  }

  GenerateResumeResponse.fromJson(dynamic json) {
    _resumeData = json['resume_data'] != null
        ? ResumeData.fromJson(json['resume_data'])
        : null;
    _pdfBase64 = json['pdf_base64'];
    _regeneratedSections = json['regenerated_sections'] != null
        ? json['regenerated_sections'].cast<String>()
        : [];
  }

  ResumeData? _resumeData;
  String? _pdfBase64;
  List<String>? _regeneratedSections;

  ResumeData? get resumeData => _resumeData;

  String? get pdfBase64 => _pdfBase64;

  List<String>? get regeneratedSections => _regeneratedSections;

  set resumeData(ResumeData? value) => _resumeData = value;

  set pdfBase64(String? value) => _pdfBase64 = value;

  set regeneratedSections(List<String>? value) => _regeneratedSections = value;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_resumeData != null) {
      map['resume_data'] = _resumeData?.toJson();
    }
    map['pdf_base64'] = _pdfBase64;
    map['regenerated_sections'] = _regeneratedSections;
    return map;
  }
}

class ResumeData {
  ResumeData({
    Personal? personal,
    String? summary,
    List<WorkExperience>? workExperience,
    List<Projects>? projects,
    Skills? skills,
    List<Education>? education,
    List<String>? achievements,
    OptionalInfo? optionalInfo,
    String? keywords,
  }) {
    _personal = personal;
    _summary = summary;
    _workExperience = workExperience;
    _projects = projects;
    _skills = skills;
    _education = education;
    _achievements = achievements;
    _optionalInfo = optionalInfo;
    _keywords = keywords;
  }

  ResumeData.fromJson(dynamic json) {
    _personal = json['personal'] != null
        ? Personal.fromJson(json['personal'])
        : null;
    _summary = json['summary'];
    if (json['work_experience'] != null) {
      _workExperience = [];
      json['work_experience'].forEach((v) {
        _workExperience?.add(WorkExperience.fromJson(v));
      });
    }
    if (json['projects'] != null) {
      _projects = [];
      json['projects'].forEach((v) {
        _projects?.add(Projects.fromJson(v));
      });
    }
    _skills = json['skills'] != null ? Skills.fromJson(json['skills']) : null;
    if (json['education'] != null) {
      _education = [];
      json['education'].forEach((v) {
        _education?.add(Education.fromJson(v));
      });
    }
    _achievements = json['achievements'] != null
        ? json['achievements'].cast<String>()
        : [];
    _optionalInfo = json['optional_info'] != null
        ? OptionalInfo.fromJson(json['optional_info'])
        : null;
    _keywords = json['keywords'];
  }

  Personal? _personal;
  String? _summary;
  List<WorkExperience>? _workExperience;
  List<Projects>? _projects;
  Skills? _skills;
  List<Education>? _education;
  List<String>? _achievements;
  OptionalInfo? _optionalInfo;
  String? _keywords;

  Personal? get personal => _personal;

  String? get summary => _summary;

  List<WorkExperience>? get workExperience => _workExperience;

  List<Projects>? get projects => _projects;

  Skills? get skills => _skills;

  List<Education>? get education => _education;

  List<String>? get achievements => _achievements;

  OptionalInfo? get optionalInfo => _optionalInfo;

  String? get keywords => _keywords;

  set personal(Personal? value) => _personal = value;

  set summary(String? value) => _summary = value;

  set workExperience(List<WorkExperience>? value) => _workExperience = value;

  set projects(List<Projects>? value) => _projects = value;

  set skills(Skills? value) => _skills = value;

  set education(List<Education>? value) => _education = value;

  set achievements(List<String>? value) => _achievements = value;

  set optionalInfo(OptionalInfo? value) => _optionalInfo = value;

  set keywords(String? value) => _keywords = value;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_personal != null) {
      map['personal'] = _personal?.toJson();
    }
    map['summary'] = _summary;
    if (_workExperience != null) {
      map['work_experience'] = _workExperience?.map((v) => v.toJson()).toList();
    }
    if (_projects != null) {
      map['projects'] = _projects?.map((v) => v.toJson()).toList();
    }
    if (_skills != null) {
      map['skills'] = _skills?.toJson();
    }
    if (_education != null) {
      map['education'] = _education?.map((v) => v.toJson()).toList();
    }
    map['achievements'] = _achievements;
    if (_optionalInfo != null) {
      map['optional_info'] = _optionalInfo?.toJson();
    }
    map['keywords'] = _keywords;
    return map;
  }
}

class OptionalInfo {
  OptionalInfo({
    List<String>? languages,
    List<dynamic>? volunteerWork,
    List<String>? hobbiesAndInterests,
    List<String>? references,
  }) {
    _languages = languages;
    _volunteerWork = volunteerWork;
    _hobbiesAndInterests = hobbiesAndInterests;
    _references = references;
  }

  OptionalInfo.fromJson(dynamic json) {
    _languages = json['languages'] != null
        ? json['languages'].cast<String>()
        : [];
    if (json['volunteer_work'] != null) {
      _volunteerWork = [];
      json['volunteer_work'].forEach((v) {
        //_volunteerWork?.add(Dynamic.fromJson(v));
      });
    }
    _hobbiesAndInterests = json['hobbies_and_interests'] != null
        ? json['hobbies_and_interests'].cast<String>()
        : [];
    _references = json['references'] != null
        ? json['references'].cast<String>()
        : [];
  }

  List<String>? _languages;
  List<dynamic>? _volunteerWork;
  List<String>? _hobbiesAndInterests;
  List<String>? _references;

  List<String>? get languages => _languages;

  List<dynamic>? get volunteerWork => _volunteerWork;

  List<String>? get hobbiesAndInterests => _hobbiesAndInterests;

  List<String>? get references => _references;

  set languages(List<String>? value) => _languages = value;

  set volunteerWork(List<dynamic>? value) => _volunteerWork = value;

  set hobbiesAndInterests(List<String>? value) => _hobbiesAndInterests = value;

  set references(List<String>? value) => _references = value;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['languages'] = _languages;
    if (_volunteerWork != null) {
      map['volunteer_work'] = _volunteerWork?.map((v) => v.toJson()).toList();
    }
    map['hobbies_and_interests'] = _hobbiesAndInterests;
    map['references'] = _references;
    return map;
  }
}

class Education {
  Education({
    String? degree,
    String? university,
    String? fromDate,
    String? toDate,
    List<String>? courses,
  }) {
    _degree = degree;
    _university = university;
    _fromDate = fromDate;
    _toDate = toDate;
    _courses = courses;
  }

  Education.fromJson(dynamic json) {
    _degree = json['degree'];
    _university = json['university'];
    _fromDate = json['from_date'];
    _toDate = json['to_date'];
    _courses = json['courses'] != null ? json['courses'].cast<String>() : [];
  }

  String? _degree;
  String? _university;
  String? _fromDate;
  String? _toDate;
  List<String>? _courses;

  String? get degree => _degree;

  String? get university => _university;

  String? get fromDate => _fromDate;

  String? get toDate => _toDate;

  List<String>? get courses => _courses;

  set degree(String? value) => _degree = value;

  set university(String? value) => _university = value;

  set fromDate(String? value) => _fromDate = value;

  set toDate(String? value) => _toDate = value;

  set courses(List<String>? value) => _courses = value;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['degree'] = _degree;
    map['university'] = _university;
    map['from_date'] = _fromDate;
    map['to_date'] = _toDate;
    map['courses'] = _courses;
    return map;
  }
}

class Skills {
  Skills({
    List<String>? softSkills,
    List<String>? hardSkills,
    List<String>? toolsAndTechnologies,
  }) {
    _softSkills = softSkills;
    _hardSkills = hardSkills;
    _toolsAndTechnologies = toolsAndTechnologies;
  }

  Skills.fromJson(dynamic json) {
    _softSkills = json['soft_skills'] != null
        ? json['soft_skills'].cast<String>()
        : [];
    _hardSkills = json['hard_skills'] != null
        ? json['hard_skills'].cast<String>()
        : [];
    _toolsAndTechnologies = json['tools_and_technologies'] != null
        ? json['tools_and_technologies'].cast<String>()
        : [];
  }

  List<String>? _softSkills;
  List<String>? _hardSkills;
  List<String>? _toolsAndTechnologies;

  List<String>? get softSkills => _softSkills;

  List<String>? get hardSkills => _hardSkills;

  List<String>? get toolsAndTechnologies => _toolsAndTechnologies;

  set softSkills(List<String>? value) => _softSkills = value;

  set hardSkills(List<String>? value) => _hardSkills = value;

  set toolsAndTechnologies(List<String>? value) =>
      _toolsAndTechnologies = value;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['soft_skills'] = _softSkills;
    map['hard_skills'] = _hardSkills;
    map['tools_and_technologies'] = _toolsAndTechnologies;
    return map;
  }
}

class Projects {
  Projects({
    String? name,
    String? type,
    String? link,
    dynamic resources,
    String? fromDate,
    String? toDate,
    List<String>? description,
  }) {
    _name = name;
    _type = type;
    _link = link;
    _resources = resources;
    _fromDate = fromDate;
    _toDate = toDate;
    _description = description;
  }

  Projects.fromJson(dynamic json) {
    _name = json['name'];
    _type = json['type'];
    _link = json['link'];
    _resources = json['resources'];
    _fromDate = json['from_date'];
    _toDate = json['to_date'];
    _description = json['description'] != null
        ? json['description'].cast<String>()
        : [];
  }

  String? _name;
  String? _type;
  String? _link;
  dynamic _resources;
  String? _fromDate;
  String? _toDate;
  List<String>? _description;

  String? get name => _name;

  String? get type => _type;

  String? get link => _link;

  dynamic get resources => _resources;

  String? get fromDate => _fromDate;

  String? get toDate => _toDate;

  List<String>? get description => _description;

  set name(String? value) => _name = value;

  set type(String? value) => _type = value;

  set link(String? value) => _link = value;

  set resources(dynamic value) => _resources = value;

  set fromDate(String? value) => _fromDate = value;

  set toDate(String? value) => _toDate = value;

  set description(List<String>? value) => _description = value;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['type'] = _type;
    map['link'] = _link;
    map['resources'] = _resources;
    map['from_date'] = _fromDate;
    map['to_date'] = _toDate;
    map['description'] = _description;
    return map;
  }
}

class WorkExperience {
  WorkExperience({
    String? role,
    String? company,
    String? location,
    String? fromDate,
    String? toDate,
    List<String>? description,
  }) {
    _role = role;
    _company = company;
    _location = location;
    _fromDate = fromDate;
    _toDate = toDate;
    _description = description;
  }

  WorkExperience.fromJson(dynamic json) {
    _role = json['role'];
    _company = json['company'];
    _location = json['location'];
    _fromDate = json['from_date'];
    _toDate = json['to_date'];
    _description = json['description'] != null
        ? json['description'].cast<String>()
        : [];
  }

  String? _role;
  String? _company;
  String? _location;
  String? _fromDate;
  String? _toDate;
  List<String>? _description;

  String? get role => _role;

  String? get company => _company;

  String? get location => _location;

  String? get fromDate => _fromDate;

  String? get toDate => _toDate;

  List<String>? get description => _description;

  set role(String? value) => _role = value;

  set company(String? value) => _company = value;

  set location(String? value) => _location = value;

  set fromDate(String? value) => _fromDate = value;

  set toDate(String? value) => _toDate = value;

  set description(List<String>? value) => _description = value;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['role'] = _role;
    map['company'] = _company;
    map['location'] = _location;
    map['from_date'] = _fromDate;
    map['to_date'] = _toDate;
    map['description'] = _description;
    return map;
  }
}

class Personal {
  Personal({
    String? name,
    String? phone,
    String? email,
    String? linkedin,
    String? personalWebsite,
  }) {
    _name = name;
    _phone = phone;
    _email = email;
    _linkedin = linkedin;
    _personalWebsite = personalWebsite;
  }

  Personal.fromJson(dynamic json) {
    _name = json['name'];
    _phone = json['phone'];
    _email = json['email'];
    _linkedin = json['linkedin'];
    _personalWebsite = json['personal_website'];
  }

  String? _name;
  String? _phone;
  String? _email;
  String? _linkedin;
  String? _personalWebsite;

  String? get name => _name;

  String? get phone => _phone;

  String? get email => _email;

  String? get linkedin => _linkedin;

  String? get personalWebsite => _personalWebsite;

  set name(String? value) => _name = value;

  set phone(String? value) => _phone = value;

  set email(String? value) => _email = value;

  set linkedin(String? value) => _linkedin = value;

  set personalWebsite(String? value) => _personalWebsite = value;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['phone'] = _phone;
    map['email'] = _email;
    map['linkedin'] = _linkedin;
    map['personal_website'] = _personalWebsite;
    return map;
  }
}
