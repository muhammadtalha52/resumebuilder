class AllFoldersResponse {
  AllFoldersResponse({
    String? status,
    String? message,
    List<ParentFolder>? data,
    int? count,
  }) {
    _status = status;
    _message = message;
    _parentFolders = data;
    _count = count;
  }

  AllFoldersResponse.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    if (json['data'] != null) {
      _parentFolders = [];
      json['data'].forEach((v) {
        _parentFolders?.add(ParentFolder.fromJson(v));
      });
    }
    _count = json['count'];
  }

  String? _status;
  String? _message;
  List<ParentFolder>? _parentFolders;
  int? _count;

  String? get status => _status;

  String? get message => _message;

  List<ParentFolder>? get parentFolders => _parentFolders;

  int? get count => _count;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    if (_parentFolders != null) {
      map['data'] = _parentFolders?.map((v) => v.toJson()).toList();
    }
    map['count'] = _count;
    return map;
  }
}

class ParentFolder {
  ParentFolder({
    int? id,
    String? name,
    int? user,
    String? userEmail,
    dynamic parent,
    int? level,
    String? description,
    List<Subfolders>? subfolders,
    int? itemsCount,
    String? fullPath,
    String? createdAt,
    String? updatedAt,
  }) {
    _id = id;
    _name = name;
    _user = user;
    _userEmail = userEmail;
    _parent = parent;
    _level = level;
    _description = description;
    _subfolders = subfolders;
    _itemsCount = itemsCount;
    _fullPath = fullPath;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
  }

  ParentFolder.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
    _user = json['user'];
    _userEmail = json['user_email'];
    _parent = json['parent'];
    _level = json['level'];
    _description = json['description'];
    if (json['subfolders'] != null) {
      _subfolders = [];
      json['subfolders'].forEach((v) {
        _subfolders?.add(Subfolders.fromJson(v));
      });
    }
    _itemsCount = json['items_count'];
    _fullPath = json['full_path'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }

  int? _id;
  String? _name;
  int? _user;
  String? _userEmail;
  dynamic _parent;
  int? _level;
  String? _description;
  List<Subfolders>? _subfolders;
  int? _itemsCount;
  String? _fullPath;
  String? _createdAt;
  String? _updatedAt;

  int? get id => _id;

  String? get name => _name;

  int? get user => _user;

  String? get userEmail => _userEmail;

  dynamic get parent => _parent;

  int? get level => _level;

  String? get description => _description;

  List<Subfolders>? get subfolders => _subfolders;

  int? get itemsCount => _itemsCount;

  String? get fullPath => _fullPath;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['user'] = _user;
    map['user_email'] = _userEmail;
    map['parent'] = _parent;
    map['level'] = _level;
    map['description'] = _description;
    if (_subfolders != null) {
      map['subfolders'] = _subfolders?.map((v) => v.toJson()).toList();
    }
    map['items_count'] = _itemsCount;
    map['full_path'] = _fullPath;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    return map;
  }
}

class Subfolders {
  Subfolders({int? id, String? name, int? level, String? createdAt}) {
    _id = id;
    _name = name;
    _level = level;
    _createdAt = createdAt;
  }

  Subfolders.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
    _level = json['level'];
    _createdAt = json['created_at'];
  }

  int? _id;
  String? _name;
  int? _level;
  String? _createdAt;

  int? get id => _id;

  String? get name => _name;

  int? get level => _level;

  String? get createdAt => _createdAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['level'] = _level;
    map['created_at'] = _createdAt;
    return map;
  }
}
