import 'package:shared_preferences/shared_preferences.dart';

class LaunchService {
  static const String _keyFirstLaunch = 'is_first_launch';

  static Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyFirstLaunch) ?? true;
    } catch (e) {
      return true;
    }
  }

  static Future<void> setFirstLaunchComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyFirstLaunch, false);
    } catch (e) {
      // Ignorer
    }
  }

  static Future<void> resetFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyFirstLaunch, true);
    } catch (e) {
      // Ignorer
    }
  }
}