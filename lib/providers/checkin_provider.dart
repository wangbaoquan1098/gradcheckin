import 'package:flutter/foundation.dart';
import '../../core/constants/app_dates.dart';
import '../../data/repositories/checkin_repository.dart';

/// 操作历史项
class CheckinHistoryItem {
  final DateTime date;
  final bool isCheckin;
  final DateTime operationTime;

  CheckinHistoryItem({
    required this.date,
    required this.isCheckin,
    required this.operationTime,
  });
}

/// 打卡状态管理
class CheckinProvider extends ChangeNotifier {
  final CheckinRepository _repository = CheckinRepository();
  Set<String> _checkedDates = {};
  List<OperationRecord> _history = [];
  bool _isLoading = true;
  Map<String, bool> _currentMonthCheckins = {};
  
  Set<String> get checkedDates => _checkedDates;
  bool get isLoading => _isLoading;
  List<OperationRecord> get history => _history;
  Map<String, bool> get currentMonthCheckins => _currentMonthCheckins;

  CheckinProvider() {
    _loadCheckins();
  }

  /// 加载打卡记录
  Future<void> _loadCheckins() async {
    try {
      _checkedDates = await _repository.getCheckedDates();
      _history = await _repository.getHistory();
      debugPrint('_loadCheckins: 已加载 ${_checkedDates.length} 个打卡日期, ${_history.length} 条历史');
    } catch (e) {
      debugPrint('加载打卡记录失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新打卡记录
  Future<void> refresh() async {
    await _loadCheckins();
  }

  /// 切换打卡状态
  Future<void> toggleCheckin(DateTime date) async {
    // 不允许对未来日期打卡
    if (date.isAfter(DateTime.now())) {
      return;
    }

    // 检查日期是否在允许范围内
    if (date.isBefore(AppDates.checkinStartDate) ||
        date.isAfter(AppDates.checkinEndDate)) {
      return;
    }

    final key = _dateToKey(date);
    await _repository.toggleCheckin(key);
    
    // 更新本地状态
    if (_checkedDates.contains(key)) {
      _checkedDates.remove(key);
    } else {
      _checkedDates.add(key);
    }
    
    // 重新加载历史
    _history = await _repository.getHistory();
    
    // 刷新当月打卡数据
    await loadMonthCheckins(date.year, date.month);
    
    debugPrint('toggleCheckin 完成: $key');
    notifyListeners();
  }

  /// 加载指定月份的打卡数据
  Future<void> loadMonthCheckins(int year, int month) async {
    _currentMonthCheckins = await _repository.getMonthCheckins(year, month);
    notifyListeners();
  }

  /// 检查指定日期是否已打卡
  bool isCheckedIn(DateTime date) {
    final key = _dateToKey(date);
    return _checkedDates.contains(key);
  }

  /// 检查指定日期是否是未来日期
  bool isFutureDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isAfter(today);
  }

  /// 获取今日打卡状态
  bool get todayCheckedIn {
    final today = DateTime.now();
    return isCheckedIn(today);
  }

  /// 获取打卡统计（已打卡天数）
  int get totalCheckins {
    return _checkedDates.length;
  }

  /// 获取本月打卡率
  double getMonthCheckinRate(int year, int month) {
    final now = DateTime.now();
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    // 如果是当月，只计算到今天
    int totalDays;
    if (year == now.year && month == now.month) {
      totalDays = now.day;
    } else if (year > now.year || (year == now.year && month > now.month)) {
      // 未来月份
      return 0;
    } else {
      totalDays = daysInMonth;
    }
    
    if (totalDays <= 0) return 0;
    
    int checkedDays = 0;
    for (int day = 1; day <= totalDays; day++) {
      final key = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      if (_checkedDates.contains(key)) {
        checkedDays++;
      }
    }
    
    return checkedDays / totalDays;
  }

  /// 获取总体打卡率（从开始到当前）
  double get totalCheckinRate {
    final now = DateTime.now();
    final startDate = AppDates.checkinStartDate;
    final endDate = AppDates.checkinEndDate;

    // 如果今天还在开始日期之前，返回0
    if (now.isBefore(startDate)) return 0;

    // 计算应该打卡的总天数（从开始到今天，但不超过结束日期）
    final effectiveEndDate = now.isAfter(endDate) ? endDate : now;
    final totalDays = effectiveEndDate.difference(startDate).inDays + 1;
    if (totalDays <= 0) return 0;

    // 只计算在有效范围内的打卡记录
    int validCheckins = 0;
    final startKey = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endKey = '${effectiveEndDate.year}-${effectiveEndDate.month.toString().padLeft(2, '0')}-${effectiveEndDate.day.toString().padLeft(2, '0')}';

    for (final dateKey in _checkedDates) {
      if (dateKey.compareTo(startKey) >= 0 && dateKey.compareTo(endKey) <= 0) {
        validCheckins++;
      }
    }

    return validCheckins / totalDays;
  }

  /// 获取打卡历史（按操作时间倒序）
  List<CheckinHistoryItem> get historyRecords {
    return _history.map((r) {
      final parts = r.dateKey.split('-');
      return CheckinHistoryItem(
        date: DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
        isCheckin: r.isCheckedIn,
        operationTime: r.operationTime,
      );
    }).toList();
  }

  /// 日期转键名
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
