import 'package:shared_preferences/shared_preferences.dart';

/// 日期配置管理类
class AppDates {
  // 默认值
  static final DateTime _defaultStartDate = DateTime(2026, 3, 1);
  static final DateTime _defaultEndDate = DateTime(2026, 12, 25, 8, 0);

  // SharedPreferences keys
  static const String _startDateKey = 'checkin_start_date';
  static const String _endDateKey = 'checkin_end_date';

  // 缓存值
  static DateTime? _cachedStartDate;
  static DateTime? _cachedEndDate;

  /// 获取打卡开始日期
  static DateTime get checkinStartDate {
    return _cachedStartDate ?? _defaultStartDate;
  }

  /// 获取打卡结束日期（考研当天早上8点）
  static DateTime get checkinEndDate {
    return _cachedEndDate ?? _defaultEndDate;
  }

  /// 获取考研日期（用于倒计时）
  static DateTime get graduateExamDate {
    return checkinEndDate;
  }

  /// 从 SharedPreferences 加载日期设置
  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final startDateStr = prefs.getString(_startDateKey);
    if (startDateStr != null) {
      _cachedStartDate = DateTime.parse(startDateStr);
    }

    final endDateStr = prefs.getString(_endDateKey);
    if (endDateStr != null) {
      _cachedEndDate = DateTime.parse(endDateStr);
    }
  }

  /// 保存日期设置到 SharedPreferences
  static Future<void> saveDates(DateTime startDate, DateTime endDate) async {
    final prefs = await SharedPreferences.getInstance();

    // 只保留日期部分
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day, 8, 0);

    await prefs.setString(_startDateKey, normalizedStart.toIso8601String());
    await prefs.setString(_endDateKey, normalizedEnd.toIso8601String());

    _cachedStartDate = normalizedStart;
    _cachedEndDate = normalizedEnd;
  }

  /// 导出当前日期设置
  static Map<String, String> exportDateSettings() {
    return {
      'start_date': checkinStartDate.toIso8601String(),
      'end_date': checkinEndDate.toIso8601String(),
    };
  }

  /// 导入日期设置
  static Future<void> importDateSettings({
    required String startDate,
    required String endDate,
  }) async {
    await saveDates(
      DateTime.parse(startDate),
      DateTime.parse(endDate),
    );
  }

  /// 重置为默认日期
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_startDateKey);
    await prefs.remove(_endDateKey);
    _cachedStartDate = null;
    _cachedEndDate = null;
  }

  /// 计算某日期是第几周（从开始日期的周为第一周）
  static int getWeekNumber(DateTime date) {
    final startDate = checkinStartDate;
    // 找到开始日期所在周的周一
    final startWeekday = startDate.weekday; // 1=周一, 7=周日
    final startOfWeek = startDate.subtract(Duration(days: startWeekday - 1));

    // 找到目标日期所在周的周一
    final targetWeekday = date.weekday;
    final targetStartOfWeek = date.subtract(Duration(days: targetWeekday - 1));

    // 计算周数差
    final daysDifference = targetStartOfWeek.difference(startOfWeek).inDays;
    final weekNumber = (daysDifference / 7).floor() + 1;

    return weekNumber > 0 ? weekNumber : 1;
  }
}
