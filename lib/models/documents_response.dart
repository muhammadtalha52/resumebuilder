class DocumentsResponse {
  DocumentsResponse({
    String? status,
    String? message,
    List<Data>? data,
    int? count,
  }) {
    _status = status;
    _message = message;
    _data = data;
    _count = count;
  }

  DocumentsResponse.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(Data.fromJson(v));
      });
    }
    _count = json['count'];
  }

  String? _status;
  String? _message;
  List<Data>? _data;
  int? _count;

  String? get status => _status;

  String? get message => _message;

  List<Data>? get data => _data;

  int? get count => _count;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    map['count'] = _count;
    return map;
  }
}

class Data {
  Data({
    int? id,
    int? folder,
    String? folderName,
    String? folderFullPath,
    int? user,
    String? userEmail,
    String? name,
    String? s3Filename,
    String? fileType,
    int? fileSize,
    String? description,
    Metadata? metadata,
    String? fullPath,
    String? createdAt,
    String? updatedAt,
  }) {
    _id = id;
    _folder = folder;
    _folderName = folderName;
    _folderFullPath = folderFullPath;
    _user = user;
    _userEmail = userEmail;
    _name = name;
    _s3Filename = s3Filename;
    _fileType = fileType;
    _fileSize = fileSize;
    _description = description;
    _metadata = metadata;
    _fullPath = fullPath;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
  }

  Data.fromJson(dynamic json) {
    _id = json['id'];
    _folder = json['folder'];
    _folderName = json['folder_name'];
    _folderFullPath = json['folder_full_path'];
    _user = json['user'];
    _userEmail = json['user_email'];
    _name = json['name'];
    _s3Filename = json['s3_filename'];
    _fileType = json['file_type'];
    _fileSize = json['file_size'];
    _description = json['description'];
    _metadata = json['metadata'] != null
        ? Metadata.fromJson(json['metadata'])
        : null;
    _fullPath = json['full_path'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }

  int? _id;
  int? _folder;
  String? _folderName;
  String? _folderFullPath;
  int? _user;
  String? _userEmail;
  String? _name;
  String? _s3Filename;
  String? _fileType;
  int? _fileSize;
  String? _description;
  Metadata? _metadata;
  String? _fullPath;
  String? _createdAt;
  String? _updatedAt;

  int? get id => _id;

  int? get folder => _folder;

  String? get folderName => _folderName;

  String? get folderFullPath => _folderFullPath;

  int? get user => _user;

  String? get userEmail => _userEmail;

  String? get name => _name;

  String? get s3Filename => _s3Filename;

  String? get fileType => _fileType;

  int? get fileSize => _fileSize;

  String? get description => _description;

  Metadata? get metadata => _metadata;

  String? get fullPath => _fullPath;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['folder'] = _folder;
    map['folder_name'] = _folderName;
    map['folder_full_path'] = _folderFullPath;
    map['user'] = _user;
    map['user_email'] = _userEmail;
    map['name'] = _name;
    map['s3_filename'] = _s3Filename;
    map['file_type'] = _fileType;
    map['file_size'] = _fileSize;
    map['description'] = _description;
    if (_metadata != null) {
      map['metadata'] = _metadata?.toJson();
    }
    map['full_path'] = _fullPath;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    return map;
  }
}

class Metadata {
  Metadata({
    String? status,
    String? company,
    String? position,
    String? dateApplied,
  }) {
    _status = status;
    _company = company;
    _position = position;
    _dateApplied = dateApplied;
  }

  Metadata.fromJson(dynamic json) {
    _status = json['status'];
    _company = json['company'];
    _position = json['position'];
    _dateApplied = json['date_applied'];
  }

  String? _status;
  String? _company;
  String? _position;
  String? _dateApplied;

  String? get status => _status;

  String? get company => _company;

  String? get position => _position;

  String? get dateApplied => _dateApplied;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['company'] = _company;
    map['position'] = _position;
    map['date_applied'] = _dateApplied;
    return map;
  }
}
