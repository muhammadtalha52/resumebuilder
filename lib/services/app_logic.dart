import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import '../providers/auth_provider.dart';
import '../utils/keys.dart';

class AppLogic {
  String? userEmail;

  String accessToken = '';
  User? user;
  String currentLocale = 'kr';
  final box = GetStorage();

  Future<void> init() async {
    currentLocale = box.read(AppKeys.currentLocale) ?? 'kr';

    String? userPref = box.read(AppKeys.user);
    if (userPref != null) {}
    String? accessTokenPref = box.read(AppKeys.accessToken);
    if (accessTokenPref != null) {
      accessToken = accessTokenPref;
    }
  }

  void clearDataAndRouteToHome(BuildContext context) {
    accessToken = '';
    user = null;
    box.erase();

  }
}
