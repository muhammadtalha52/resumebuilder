import 'package:skillresy/models/all_folders_response.dart';

class CreateParentFolderResponse {
  CreateParentFolderResponse({
    String? status,
    String? message,
    ParentFolder? data,
  }) {
    _status = status;
    _message = message;
    _data = data;
  }

  CreateParentFolderResponse.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? ParentFolder.fromJson(json['data']) : null;
  }

  String? _status;
  String? _message;
  ParentFolder? _data;

  String? get status => _status;

  String? get message => _message;

  ParentFolder? get data => _data;

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
