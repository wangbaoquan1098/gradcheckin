import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_dates.dart';

/// 应用设置存储
class AppSettingsService {
  static const String _darkModeKey = 'dark_mode_enabled';

  static bool _isDarkMode = false;

  static bool get isDarkMode => _isDarkMode;

  static Future<void> loadFromPrefs() async {
    await AppDates.loadFromPrefs();

    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
  }

  static Future<void> setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
    _isDarkMode = enabled;
  }

  static Map<String, dynamic> exportSettings() {
    return {
      ...AppDates.exportDateSettings(),
      'dark_mode': _isDarkMode,
    };
  }

  static Future<void> importSettings(Map<String, dynamic> settings) async {
    final startDate = settings['start_date'];
    final endDate = settings['end_date'];
    final darkMode = settings['dark_mode'];

    if (startDate is! String || endDate is! String || darkMode is! bool) {
      throw const FormatException('备份文件格式不正确，设置项缺失');
    }

    DateTime.parse(startDate);
    DateTime.parse(endDate);

    await AppDates.importDateSettings(
      startDate: startDate,
      endDate: endDate,
    );
    await setDarkMode(darkMode);
  }
}
