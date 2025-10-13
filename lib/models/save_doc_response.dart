class SaveDocResponse {
  SaveDocResponse({
    String? status,
    String? message,
    String? s3FileName,
    String? fileType,
    String? mimeType,
  }) {
    _status = status;
    _message = message;
    _s3FileName = s3FileName;
    _fileType = fileType;
    _mimeType = mimeType;
  }

  SaveDocResponse.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _s3FileName = json['s3_file_name'];
    _fileType = json['file_type'];
    _mimeType = json['mime_type'];
  }

  String? _status;
  String? _message;
  String? _s3FileName;
  String? _fileType;
  String? _mimeType;

  String? get status => _status;

  String? get message => _message;

  String? get s3FileName => _s3FileName;

  String? get fileType => _fileType;

  String? get mimeType => _mimeType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    map['s3_file_name'] = _s3FileName;
    map['file_type'] = _fileType;
    map['mime_type'] = _mimeType;
    return map;
  }
}
