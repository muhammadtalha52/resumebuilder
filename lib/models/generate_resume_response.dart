class GenerateResumeResponse {
  GenerateResumeResponse({
    ResumeData? resumeData,
    String? pdfBase64,
    List<String>? regeneratedSections,
  }) {
    resumeData = resumeData;
    pdfBase64 = pdfBase64;
    regeneratedSections = regeneratedSections;
  }

  GenerateResumeResponse.fromJson(dynamic json) {
    resumeData = json['resume_data'] != null
        ? ResumeData.fromJson(json['resume_data'])
        : null;
    pdfBase64 = json['pdf_base64'];
    regeneratedSections = json['regenerated_sections'] != null
        ? json['regenerated_sections'].cast<String>()
        : [];
  }

  ResumeData? resumeData;
  String? pdfBase64;

  void setPdfBase64(String? pdfBase64) {
    this.pdfBase64 = pdfBase64;
  }

  List<String>? regeneratedSections;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (resumeData != null) {
      map['resume_data'] = resumeData?.toJson();
    }
    map['pdf_base64'] = pdfBase64;
    map['regenerated_sections'] = regeneratedSections;
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
    personal = personal;
    summary = summary;
    workExperience = workExperience;
    projects = projects;
    skills = skills;
    education = education;
    achievements = achievements;
    optionalInfo = optionalInfo;
    keywords = keywords;
  }

  ResumeData.fromJson(dynamic json) {
    personal = json['personal'] != null
        ? Personal.fromJson(json['personal'])
        : null;
    summary = json['summary'];
    if (json['work_experience'] != null) {
      workExperience = [];
      json['work_experience'].forEach((v) {
        workExperience?.add(WorkExperience.fromJson(v));
      });
    }
    if (json['projects'] != null) {
      projects = [];
      json['projects'].forEach((v) {
        projects?.add(Projects.fromJson(v));
      });
    }
    skills = json['skills'] != null ? Skills.fromJson(json['skills']) : null;
    if (json['education'] != null) {
      education = [];
      json['education'].forEach((v) {
        education?.add(Education.fromJson(v));
      });
    }
    achievements = json['achievements'] != null
        ? json['achievements'].cast<String>()
        : [];
    optionalInfo = json['optional_info'] != null
        ? OptionalInfo.fromJson(json['optional_info'])
        : null;
    keywords = json['keywords'];
  }

  Personal? personal;
  String? summary;
  List<WorkExperience>? workExperience;
  List<Projects>? projects;
  Skills? skills;
  List<Education>? education;
  List<String>? achievements;
  OptionalInfo? optionalInfo;
  String? keywords;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (personal != null) {
      map['personal'] = personal?.toJson();
    }
    map['summary'] = summary;
    if (workExperience != null) {
      map['work_experience'] = workExperience?.map((v) => v.toJson()).toList();
    }
    if (projects != null) {
      map['projects'] = projects?.map((v) => v.toJson()).toList();
    }
    if (skills != null) {
      map['skills'] = skills?.toJson();
    }
    if (education != null) {
      map['education'] = education?.map((v) => v.toJson()).toList();
    }
    map['achievements'] = achievements;
    if (optionalInfo != null) {
      map['optional_info'] = optionalInfo?.toJson();
    }
    map['keywords'] = keywords;
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
    languages = languages;
    volunteerWork = volunteerWork;
    hobbiesAndInterests = hobbiesAndInterests;
    references = references;
  }

  OptionalInfo.fromJson(dynamic json) {
    languages = json['languages'] != null
        ? json['languages'].cast<String>()
        : [];
    if (json['volunteer_work'] != null) {
      volunteerWork = [];
      json['volunteer_work'].forEach((v) {
        //_volunteerWork?.add(Dynamic.fromJson(v));
      });
    }
    hobbiesAndInterests = json['hobbies_and_interests'] != null
        ? json['hobbies_and_interests'].cast<String>()
        : [];
    references = json['references'] != null
        ? json['references'].cast<String>()
        : [];
  }

  List<String>? languages;
  List<dynamic>? volunteerWork;
  List<String>? hobbiesAndInterests;
  List<String>? references;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['languages'] = languages;
    if (volunteerWork != null) {
      map['volunteer_work'] = volunteerWork?.map((v) => v.toJson()).toList();
    }
    map['hobbies_and_interests'] = hobbiesAndInterests;
    map['references'] = references;
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
    degree = degree;
    university = university;
    fromDate = fromDate;
    toDate = toDate;
    courses = courses;
  }

  Education.fromJson(dynamic json) {
    degree = json['degree'];
    university = json['university'];
    fromDate = json['from_date'];
    toDate = json['to_date'];
    courses = json['courses'] != null ? json['courses'].cast<String>() : [];
  }

  String? degree;
  String? university;
  String? fromDate;
  String? toDate;
  List<String>? courses;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['degree'] = degree;
    map['university'] = university;
    map['from_date'] = fromDate;
    map['to_date'] = toDate;
    map['courses'] = courses;
    return map;
  }
}

class Skills {
  Skills({
    List<String>? softSkills,
    List<String>? hardSkills,
    List<String>? toolsAndTechnologies,
  }) {
    softSkills = softSkills;
    hardSkills = hardSkills;
    toolsAndTechnologies = toolsAndTechnologies;
  }

  Skills.fromJson(dynamic json) {
    softSkills = json['soft_skills'] != null
        ? json['soft_skills'].cast<String>()
        : [];
    hardSkills = json['hard_skills'] != null
        ? json['hard_skills'].cast<String>()
        : [];
    toolsAndTechnologies = json['tools_and_technologies'] != null
        ? json['tools_and_technologies'].cast<String>()
        : [];
  }

  List<String>? softSkills;
  List<String>? hardSkills;
  List<String>? toolsAndTechnologies;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['soft_skills'] = softSkills;
    map['hard_skills'] = hardSkills;
    map['tools_and_technologies'] = toolsAndTechnologies;
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
    name = name;
    type = type;
    link = link;
    resources = resources;
    fromDate = fromDate;
    toDate = toDate;
    description = description;
  }

  Projects.fromJson(dynamic json) {
    name = json['name'];
    type = json['type'];
    link = json['link'];
    resources = json['resources'];
    fromDate = json['from_date'];
    toDate = json['to_date'];
    description = json['description'] != null
        ? json['description'].cast<String>()
        : [];
  }

  String? name;
  String? type;
  String? link;
  dynamic resources;
  String? fromDate;
  String? toDate;
  List<String>? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['type'] = type;
    map['link'] = link;
    map['resources'] = resources;
    map['from_date'] = fromDate;
    map['to_date'] = toDate;
    map['description'] = description;
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
    role = role;
    company = company;
    location = location;
    fromDate = fromDate;
    toDate = toDate;
    description = description;
  }

  WorkExperience.fromJson(dynamic json) {
    role = json['role'];
    company = json['company'];
    location = json['location'];
    fromDate = json['from_date'];
    toDate = json['to_date'];
    description = json['description'] != null
        ? json['description'].cast<String>()
        : [];
  }

  String? role;
  String? company;
  String? location;
  String? fromDate;
  String? toDate;
  List<String>? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['role'] = role;
    map['company'] = company;
    map['location'] = location;
    map['from_date'] = fromDate;
    map['to_date'] = toDate;
    map['description'] = description;
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
    name = name;
    phone = phone;
    email = email;
    linkedin = linkedin;
    personalWebsite = personalWebsite;
  }

  Personal.fromJson(dynamic json) {
    name = json['name'];
    phone = json['phone'];
    email = json['email'];
    linkedin = json['linkedin'];
    personalWebsite = json['personal_website'];
  }

  String? name;
  String? phone;
  String? email;
  String? linkedin;
  String? personalWebsite;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['phone'] = phone;
    map['email'] = email;
    map['linkedin'] = linkedin;
    map['personal_website'] = personalWebsite;
    return map;
  }
}
