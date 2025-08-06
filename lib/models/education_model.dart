class EducationModel {
  EducationModel({String? status, String? message, Data? data}) {
    _status = status;
    _message = message;
    _data = data;
  }

  EducationModel.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  String? _status;
  String? _message;
  Data? _data;

  String? get status => _status;

  String? get message => _message;

  Data? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}

class Data {
  Data({
    List<Institutes>? institutes,
    List<Subjects>? subjects,
    List<DegreeTypes>? degreeTypes,
    List<Certificates>? certificates,
  }) {
    _institutes = institutes;
    _subjects = subjects;
    _degreeTypes = degreeTypes;
    _certificates = certificates;
  }

  Data.fromJson(dynamic json) {
    if (json['institutes'] != null) {
      _institutes = [];
      json['institutes'].forEach((v) {
        _institutes?.add(Institutes.fromJson(v));
      });
    }
    if (json['subjects'] != null) {
      _subjects = [];
      json['subjects'].forEach((v) {
        _subjects?.add(Subjects.fromJson(v));
      });
    }
    if (json['degree_types'] != null) {
      _degreeTypes = [];
      json['degree_types'].forEach((v) {
        _degreeTypes?.add(DegreeTypes.fromJson(v));
      });
    }
    if (json['certificates'] != null) {
      _certificates = [];
      json['certificates'].forEach((v) {
        _certificates?.add(Certificates.fromJson(v));
      });
    }
  }

  List<Institutes>? _institutes;
  List<Subjects>? _subjects;
  List<DegreeTypes>? _degreeTypes;
  List<Certificates>? _certificates;

  List<Institutes>? get institutes => _institutes;

  List<Subjects>? get subjects => _subjects;

  List<DegreeTypes>? get degreeTypes => _degreeTypes;

  List<Certificates>? get certificates => _certificates;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_institutes != null) {
      map['institutes'] = _institutes?.map((v) => v.toJson()).toList();
    }
    if (_subjects != null) {
      map['subjects'] = _subjects?.map((v) => v.toJson()).toList();
    }
    if (_degreeTypes != null) {
      map['degree_types'] = _degreeTypes?.map((v) => v.toJson()).toList();
    }
    if (_certificates != null) {
      map['certificates'] = _certificates?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Certificates {
  Certificates({int? id, int? user, String? userEmail, String? name}) {
    _id = id;
    _user = user;
    _userEmail = userEmail;
    _name = name;
  }

  Certificates.fromJson(dynamic json) {
    _id = json['id'];
    _user = json['user'];
    _userEmail = json['user_email'];
    _name = json['name'];
  }

  int? _id;
  int? _user;
  String? _userEmail;
  String? _name;

  int? get id => _id;

  int? get user => _user;

  String? get userEmail => _userEmail;

  String? get name => _name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['user'] = _user;
    map['user_email'] = _userEmail;
    map['name'] = _name;
    return map;
  }
}

class DegreeTypes {
  DegreeTypes({int? id, int? user, String? userEmail, String? name}) {
    _id = id;
    _user = user;
    _userEmail = userEmail;
    _name = name;
  }

  DegreeTypes.fromJson(dynamic json) {
    _id = json['id'];
    _user = json['user'];
    _userEmail = json['user_email'];
    _name = json['name'];
  }

  int? _id;
  int? _user;
  String? _userEmail;
  String? _name;

  int? get id => _id;

  int? get user => _user;

  String? get userEmail => _userEmail;

  String? get name => _name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['user'] = _user;
    map['user_email'] = _userEmail;
    map['name'] = _name;
    return map;
  }
}

class Subjects {
  Subjects({
    int? id,
    int? user,
    String? userEmail,
    int? degreeType,
    String? degreeTypeName,
    String? name,
  }) {
    _id = id;
    _user = user;
    _userEmail = userEmail;
    _degreeType = degreeType;
    _degreeTypeName = degreeTypeName;
    _name = name;
  }

  Subjects.fromJson(dynamic json) {
    _id = json['id'];
    _user = json['user'];
    _userEmail = json['user_email'];
    _degreeType = json['degree_type'];
    _degreeTypeName = json['degree_type_name'];
    _name = json['name'];
  }

  int? _id;
  int? _user;
  String? _userEmail;
  int? _degreeType;
  String? _degreeTypeName;
  String? _name;

  int? get id => _id;

  int? get user => _user;

  String? get userEmail => _userEmail;

  int? get degreeType => _degreeType;

  String? get degreeTypeName => _degreeTypeName;

  String? get name => _name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['user'] = _user;
    map['user_email'] = _userEmail;
    map['degree_type'] = _degreeType;
    map['degree_type_name'] = _degreeTypeName;
    map['name'] = _name;
    return map;
  }
}

class Institutes {
  Institutes({int? id, int? user, String? userEmail, String? name}) {
    _id = id;
    _user = user;
    _userEmail = userEmail;
    _name = name;
  }

  Institutes.fromJson(dynamic json) {
    _id = json['id'];
    _user = json['user'];
    _userEmail = json['user_email'];
    _name = json['name'];
  }

  int? _id;
  int? _user;
  String? _userEmail;
  String? _name;

  int? get id => _id;

  int? get user => _user;

  String? get userEmail => _userEmail;

  String? get name => _name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['user'] = _user;
    map['user_email'] = _userEmail;
    map['name'] = _name;
    return map;
  }
}
