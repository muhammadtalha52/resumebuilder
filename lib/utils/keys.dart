import 'package:flutter/cupertino.dart';

class AppKeys {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static const String user = 'user';
  static const String currentLocale = 'currentLocale';
  static const String accessToken = 'accessToken';
  static const String openAiApiKey =
      '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';
}
