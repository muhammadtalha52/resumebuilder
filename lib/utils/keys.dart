import 'package:flutter/cupertino.dart';

class AppKeys {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static const String user = 'user';
  static const String currentLocale = 'currentLocale';
  static const String accessToken = 'accessToken';
}

class AppMenuCodes {
  static const String releasedList = 'M000001550';
  static const String releaseRegistration = 'M000001549';
}

class SupabaseConfig {
  static const String url = 'https://kpdomkqjtkdlraqeigoo.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtwZG9ta3FqdGtkbHJhcWVpZ29vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjg3NTQ3NzMsImV4cCI6MjA0NDMzMDc3M30.PhAHIjnpaMw4BtMU2-t2Lm2Xx2Eqg6NIRTYAAshXr-Y';
}
