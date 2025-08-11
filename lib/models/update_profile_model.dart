import 'package:skillresy/models/user_model.dart';

class UpdateProfileModel {
  UpdateProfileModel({String? status, String? message, User? data}) {
    _status = status;
    _message = message;
    _data = data;
  }

  UpdateProfileModel.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? User.fromJson(json['data']) : null;
  }

  String? _status;
  String? _message;
  User? _data;

  String? get status => _status;

  String? get message => _message;

  User? get data => _data;

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
