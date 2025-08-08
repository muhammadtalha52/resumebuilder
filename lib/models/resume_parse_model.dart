import 'package:flutter/foundation.dart';

/// Main model class for resume parsing API response
class ResumeParse {
  final String? name;
  final String? summary;
  final String? phone;
  final String? email;
  final Media? media;
  final List<WorkExperience> workExperience;
  final List<Education> education;
  final Skills? skills;
  final List<Project> projects;
  final List<String> certifications;
  final List<String> achievements;

  ResumeParse({
    this.name,
    this.summary,
    this.phone,
    this.email,
    this.media,
    this.workExperience = const [],
    this.education = const [],
    this.skills,
    this.projects = const [],
    this.certifications = const [],
    this.achievements = const [],
  });

  factory ResumeParse.fromJson(Map<String, dynamic> json) {
    return ResumeParse(
      name: json['name']?.toString(),
      summary: json['summary']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      media: json['media'] != null ? Media.fromJson(json['media']) : null,
      workExperience: _parseWorkExperience(json['work_experience']),
      education: _parseEducation(json['education']),
      skills: json['skills'] != null ? Skills.fromJson(json['skills']) : null,
      projects: _parseProjects(json['projects']),
      certifications: _parseStringList(json['certifications']),
      achievements: _parseStringList(json['achievements']),
    );
  }

  static List<WorkExperience> _parseWorkExperience(dynamic data) {
    if (data == null || data is! List) return [];
    return data.map((e) => WorkExperience.fromJson(e)).toList();
  }

  static List<Education> _parseEducation(dynamic data) {
    if (data == null || data is! List) return [];
    return data.map((e) => Education.fromJson(e)).toList();
  }

  static List<Project> _parseProjects(dynamic data) {
    if (data == null || data is! List) return [];
    return data.map((e) => Project.fromJson(e)).toList();
  }

  static List<String> _parseStringList(dynamic data) {
    if (data == null || data is! List) return [];
    return data.map((e) => e.toString()).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'summary': summary,
      'phone': phone,
      'email': email,
      'media': media?.toJson(),
      'work_experience': workExperience.map((e) => e.toJson()).toList(),
      'education': education.map((e) => e.toJson()).toList(),
      'skills': skills?.toJson(),
      'projects': projects.map((e) => e.toJson()).toList(),
      'certifications': certifications,
      'achievements': achievements,
    };
  }

  /// Helper method to get first name
  String? get firstName {
    if (name == null || name!.isEmpty) return null;
    return name!.split(' ').first;
  }

  /// Helper method to get last name
  String? get lastName {
    if (name == null || name!.isEmpty) return null;
    final parts = name!.split(' ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' ');
    }
    return null;
  }

  /// Helper method to get latest work experience
  WorkExperience? get latestWorkExperience {
    if (workExperience.isEmpty) return null;
    return workExperience.first;
  }

  /// Helper method to get latest education
  Education? get latestEducation {
    if (education.isEmpty) return null;
    return education.first;
  }

  /// Helper method to calculate total years of experience
  int get totalYearsOfExperience {
    if (workExperience.isEmpty) return 0;
    
    // Find the earliest start date
    DateTime? earliestDate;
    for (var exp in workExperience) {
      final startDate = exp.parsedFromDate;
      if (startDate != null) {
        if (earliestDate == null || startDate.isBefore(earliestDate)) {
          earliestDate = startDate;
        }
      }
    }
    
    if (earliestDate == null) return 0;
    return DateTime.now().difference(earliestDate).inDays ~/ 365;
  }

  /// Check if resume has minimum required data
  bool get hasMinimumData => name != null && email != null;

  /// Transform to onboarding format
  Map<String, dynamic> toOnboardingFormat() {
    return {
      'fullName': name,
      'email': email,
      'phone': phone,
      'linkedIn': media?.linkedin,
      'website': media?.personalWebsite,
      'summary': summary,
      'workExperience': workExperience.map((e) => e.toOnboardingFormat()).toList(),
      'education': education.isNotEmpty ? education.first.toOnboardingFormat() : null,
      'skills': skills?.toOnboardingFormat(),
      'projects': projects.map((e) => e.toOnboardingFormat()).toList(),
    };
  }
}

/// Media/Social links model
class Media {
  final String? linkedin;
  final String? personalWebsite;

  Media({
    this.linkedin,
    this.personalWebsite,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      linkedin: json['linkedin']?.toString(),
      personalWebsite: json['personal_website']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'linkedin': linkedin,
      'personal_website': personalWebsite,
    };
  }

  bool get hasAnyLink => 
      (linkedin != null && linkedin!.isNotEmpty) || 
      (personalWebsite != null && personalWebsite!.isNotEmpty);
}

/// Work Experience model
class WorkExperience {
  final String? role;
  final String? company;
  final String? location;
  final String? fromDate;
  final String? toDate;
  final List<String> description;

  WorkExperience({
    this.role,
    this.company,
    this.location,
    this.fromDate,
    this.toDate,
    this.description = const [],
  });

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      role: json['role']?.toString(),
      company: json['company']?.toString(),
      location: json['location']?.toString(),
      fromDate: json['from_date']?.toString(),
      toDate: json['to_date']?.toString(),
      description: _parseDescriptions(json['description']),
    );
  }

  static List<String> _parseDescriptions(dynamic data) {
    if (data == null) return [];
    if (data is String) return [data];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'company': company,
      'location': location,
      'from_date': fromDate,
      'to_date': toDate,
      'description': description,
    };
  }

  /// Parse from date to DateTime
  DateTime? get parsedFromDate {
    if (fromDate == null) return null;
    try {
      // Handle various date formats like "May 2019", "2019-05", etc.
      final parts = fromDate!.split(' ');
      if (parts.length == 2) {
        final month = _parseMonth(parts[0]);
        final year = int.tryParse(parts[1]);
        if (month != null && year != null) {
          return DateTime(year, month);
        }
      }
    } catch (e) {
      debugPrint('Error parsing from date: $e');
    }
    return null;
  }

  /// Parse to date to DateTime
  DateTime? get parsedToDate {
    if (toDate == null || toDate!.toLowerCase() == 'current' || toDate!.toLowerCase() == 'present') {
      return null; // Current job
    }
    try {
      final parts = toDate!.split(' ');
      if (parts.length == 2) {
        final month = _parseMonth(parts[0]);
        final year = int.tryParse(parts[1]);
        if (month != null && year != null) {
          return DateTime(year, month);
        }
      }
    } catch (e) {
      debugPrint('Error parsing to date: $e');
    }
    return null;
  }

  int? _parseMonth(String monthStr) {
    const months = {
      'jan': 1, 'january': 1,
      'feb': 2, 'february': 2,
      'mar': 3, 'march': 3,
      'apr': 4, 'april': 4,
      'may': 5,
      'jun': 6, 'june': 6,
      'jul': 7, 'july': 7,
      'aug': 8, 'august': 8,
      'sep': 9, 'september': 9,
      'oct': 10, 'october': 10,
      'nov': 11, 'november': 11,
      'dec': 12, 'december': 12,
    };
    return months[monthStr.toLowerCase()];
  }

  bool get isCurrent => toDate == null || toDate!.toLowerCase() == 'current' || toDate!.toLowerCase() == 'present';

  /// Calculate duration in years
  int get durationInYears {
    final start = parsedFromDate;
    if (start == null) return 0;
    
    final end = parsedToDate ?? DateTime.now();
    return (end.difference(start).inDays / 365).round();
  }

  /// Convert to onboarding format
  Map<String, dynamic> toOnboardingFormat() {
    return {
      'jobTitle': role,
      'company': company,
      'location': location,
      'startDate': fromDate,
      'endDate': toDate,
      'currentlyWorking': isCurrent,
      'responsibilities': description,
    };
  }
}

/// Education model
class Education {
  final String? degree;
  final String? university;
  final String? fromDate;
  final String? toDate;
  final List<String> courses;

  Education({
    this.degree,
    this.university,
    this.fromDate,
    this.toDate,
    this.courses = const [],
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      degree: json['degree']?.toString(),
      university: json['university']?.toString(),
      fromDate: json['from_date']?.toString(),
      toDate: json['to_date']?.toString(),
      courses: _parseCourses(json['courses']),
    );
  }

  static List<String> _parseCourses(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'degree': degree,
      'university': university,
      'from_date': fromDate,
      'to_date': toDate,
      'courses': courses,
    };
  }

  /// Extract degree type (Bachelor's, Master's, etc.)
  String? get degreeType {
    if (degree == null) return null;
    if (degree!.toLowerCase().contains('bachelor')) return "Bachelor's";
    if (degree!.toLowerCase().contains('master')) return "Master's";
    if (degree!.toLowerCase().contains('phd') || degree!.toLowerCase().contains('doctorate')) return "PhD";
    if (degree!.toLowerCase().contains('associate')) return "Associate's";
    return null;
  }

  /// Extract major from degree
  String? get major {
    if (degree == null) return null;
    // Extract text after "in" or "of"
    final regex = RegExp(r'(?:in|of)\s+(.+)', caseSensitive: false);
    final match = regex.firstMatch(degree!);
    return match?.group(1);
  }

  /// Convert to onboarding format
  Map<String, dynamic> toOnboardingFormat() {
    return {
      'degreeType': degreeType,
      'major': major,
      'institution': university,
      'graduationDate': toDate,
      'courses': courses,
    };
  }
}

/// Skills model
class Skills {
  final List<String> softSkills;
  final List<String> hardSkills;
  final List<String> toolsAndTechnologies;

  Skills({
    this.softSkills = const [],
    this.hardSkills = const [],
    this.toolsAndTechnologies = const [],
  });

  factory Skills.fromJson(Map<String, dynamic> json) {
    return Skills(
      softSkills: _parseSkillList(json['soft_skills']),
      hardSkills: _parseSkillList(json['hard_skills']),
      toolsAndTechnologies: _parseSkillList(json['tools_and_technologies']),
    );
  }

  static List<String> _parseSkillList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'soft_skills': softSkills,
      'hard_skills': hardSkills,
      'tools_and_technologies': toolsAndTechnologies,
    };
  }

  /// Get all skills combined
  List<String> get allSkills => [...softSkills, ...hardSkills, ...toolsAndTechnologies];

  /// Get top skills (first N from each category)
  List<String> getTopSkills({int count = 5}) {
    final List<String> topSkills = [];
    
    // Add top hard skills first (most important)
    topSkills.addAll(hardSkills.take(count));
    
    // Add tools if we have room
    if (topSkills.length < count * 2) {
      topSkills.addAll(toolsAndTechnologies.take(count ~/ 2));
    }
    
    // Add soft skills if we have room
    if (topSkills.length < count * 3) {
      topSkills.addAll(softSkills.take(count ~/ 3));
    }
    
    return topSkills;
  }

  /// Convert to onboarding format
  Map<String, dynamic> toOnboardingFormat() {
    return {
      'technicalSkills': hardSkills,
      'softSkills': softSkills,
      'tools': toolsAndTechnologies,
    };
  }
}

/// Project model
class Project {
  final String? name;
  final String? type;
  final String? link;
  final List<Resource>? resources;
  final String? fromDate;
  final String? toDate;
  final List<String> description;

  Project({
    this.name,
    this.type,
    this.link,
    this.resources,
    this.fromDate,
    this.toDate,
    this.description = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name']?.toString(),
      type: json['type']?.toString(),
      link: json['link']?.toString(),
      resources: _parseResources(json['resources']),
      fromDate: json['from_date']?.toString(),
      toDate: json['to_date']?.toString(),
      description: _parseDescriptions(json['description']),
    );
  }

  static List<Resource>? _parseResources(dynamic data) {
    if (data == null) return null;
    if (data is List) {
      return data.map((e) => Resource.fromJson(e)).toList();
    }
    return null;
  }

  static List<String> _parseDescriptions(dynamic data) {
    if (data == null) return [];
    if (data is String) return [data];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'link': link,
      'resources': resources?.map((e) => e.toJson()).toList(),
      'from_date': fromDate,
      'to_date': toDate,
      'description': description,
    };
  }

  bool get isProfessional => type?.toLowerCase() == 'professional';
  bool get isPersonal => type?.toLowerCase() == 'personal';
  bool get isAcademic => type?.toLowerCase() == 'academic';

  /// Get all available links
  List<String> get allLinks {
    final links = <String>[];
    if (link != null && link!.isNotEmpty) links.add(link!);
    if (resources != null) {
      for (var resource in resources!) {
        if (resource.link != null && resource.link!.isNotEmpty) {
          links.add(resource.link!);
        }
      }
    }
    return links;
  }

  /// Convert to onboarding format
  Map<String, dynamic> toOnboardingFormat() {
    return {
      'name': name,
      'type': type,
      'description': description.join(' '),
      'technologies': [], // Could be extracted from description
      'links': allLinks,
    };
  }
}

/// Resource model for project resources
class Resource {
  final String? name;
  final String? link;

  Resource({
    this.name,
    this.link,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      name: json['name']?.toString(),
      link: json['link']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'link': link,
    };
  }

  bool get hasValidLink => link != null && link!.isNotEmpty;
}