import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';

import '../models/user_model.dart';
import '../utils/keys.dart';

class AppLogic {
  String? userEmail;

  String accessToken = '';
  User? user;
  String currentLocale = 'kr';
  final box = GetStorage();

  Future<void> init() async {
    currentLocale = box.read(AppKeys.currentLocale) ?? 'kr';

    // Load user data from storage
    String? userPref = box.read(AppKeys.user);
    if (userPref != null) {
      try {
        final userJson = jsonDecode(userPref);
        user = User.fromJson(userJson);
      } catch (e) {
        print('Error parsing user data: $e');
      }
    }

    // Load access token from storage
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
