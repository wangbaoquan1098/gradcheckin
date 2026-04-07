import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/app_dates.dart';

/// 考研倒计时状态管理
class CountdownProvider extends ChangeNotifier {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  Duration get remaining => _remaining;

  CountdownProvider() {
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    _remaining = AppDates.graduateExamDate.difference(DateTime.now());
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
    }
    notifyListeners();
  }

  /// 总备考天数（从3月1日到12月25日）
  int get totalDays => AppDates.checkinEndDate.difference(AppDates.checkinStartDate).inDays;
  
  /// 已过去的天数（从3月1日到今天）
  int get elapsedDays {
    final now = DateTime.now();
    if (now.isBefore(AppDates.checkinStartDate)) return 0;
    if (now.isAfter(AppDates.checkinEndDate)) return totalDays;
    return now.difference(AppDates.checkinStartDate).inDays;
  }
  
  /// 剩余天数
  String get days => _remaining.inDays.toString().padLeft(3, '0');
  
  /// 已过去的时间百分比
  String get elapsedPercentage {
    if (totalDays <= 0) return '100.0';
    final percentage = (elapsedDays / totalDays * 100);
    return percentage.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
