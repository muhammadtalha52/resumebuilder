import 'package:flutter/cupertino.dart';

class AppKeys {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static const String user = 'user';
  static const String currentLocale = 'currentLocale';
  static const String accessToken = 'accessToken';
}
