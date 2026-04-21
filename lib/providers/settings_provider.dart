import 'package:flutter/foundation.dart';
import '../core/constants/app_dates.dart';
import '../core/services/app_settings_service.dart';
import '../data/repositories/checkin_repository.dart';

/// 设置状态管理
class SettingsProvider extends ChangeNotifier {
  final CheckinRepository _repository = CheckinRepository();

  DateTime _startDate = AppDates.checkinStartDate;
  DateTime _endDate = AppDates.checkinEndDate;
  bool _isDarkMode = AppSettingsService.isDarkMode;
  bool _isLoading = false;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadDates();
  }

  /// 加载保存的日期设置
  Future<void> _loadDates() async {
    await AppSettingsService.loadFromPrefs();
    _startDate = AppDates.checkinStartDate;
    _endDate = AppDates.checkinEndDate;
    _isDarkMode = AppSettingsService.isDarkMode;
    notifyListeners();
  }

  /// 重新加载已保存的日期设置
  Future<void> reload() async {
    await _loadDates();
  }

  /// 更新深色模式开关
  Future<void> setDarkMode(bool enabled) async {
    await AppSettingsService.setDarkMode(enabled);
    _isDarkMode = enabled;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    await setDarkMode(!_isDarkMode);
  }

  /// 更新起止日期
  /// 返回 true 表示成功，false 表示用户取消或失败
  Future<bool> updateDates(DateTime newStartDate, DateTime newEndDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 确保日期格式一致（只保留日期部分）
      final normalizedStart = DateTime(newStartDate.year, newStartDate.month, newStartDate.day);
      final normalizedEnd = DateTime(newEndDate.year, newEndDate.month, newEndDate.day, 8, 0);

      // 验证日期合理性
      if (normalizedEnd.isBefore(normalizedStart)) {
        debugPrint('结束日期不能早于开始日期');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 保存新日期
      await AppDates.saveDates(normalizedStart, normalizedEnd);

      // 删除范围外的记录
      await _repository.deleteRecordsOutsideRange(normalizedStart, normalizedEnd);

      // 更新本地状态
      _startDate = normalizedStart;
      _endDate = normalizedEnd;

      debugPrint('日期设置已更新: $_startDate 到 $_endDate');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('更新日期失败: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 重置为默认日期
  Future<void> resetToDefaults() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AppDates.resetToDefaults();
      _startDate = AppDates.checkinStartDate;
      _endDate = AppDates.checkinEndDate;

      // 删除所有记录（因为是重置）
      await _repository.deleteAllRecords();

      debugPrint('日期设置已重置为默认值');
    } catch (e) {
      debugPrint('重置日期失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取某日期所在的周数
  int getWeekNumber(DateTime date) {
    return AppDates.getWeekNumber(date);
  }
}
