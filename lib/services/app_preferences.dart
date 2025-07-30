import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _isFirstTimeKey = 'is_first_time';
  static const String _hasSeenWelcomeKey = 'has_seen_welcome';

  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstTimeKey) ?? true;
  }

  static Future<void> setFirstTime(bool isFirstTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstTimeKey, isFirstTime);
  }

  static Future<bool> hasSeenWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenWelcomeKey) ?? false;
  }

  static Future<void> setHasSeenWelcome(bool hasSeen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenWelcomeKey, hasSeen);
  }

  static Future<void> markWelcomeComplete() async {
    await setHasSeenWelcome(true);
    await setFirstTime(false);
  }
}
