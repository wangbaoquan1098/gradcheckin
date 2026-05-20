import '../../data/models/checkin_trend.dart';

/// 生成打卡趋势统计数据
class CheckinTrendCalculator {
  static List<CheckinTrendPeriod> buildWeeklyTrends({
    required Set<String> checkedDates,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime today,
  }) {
    final start = _dateOnly(startDate);
    final effectiveEnd = _effectiveEndDate(endDate, today);
    if (effectiveEnd.isBefore(start)) {
      return [];
    }

    final firstWeekStart = start.subtract(Duration(days: start.weekday - 1));
    final periods = <CheckinTrendPeriod>[];
    var periodStart = firstWeekStart;

    while (!periodStart.isAfter(effectiveEnd)) {
      final periodEnd = periodStart.add(const Duration(days: 6));
      final actualStart = _maxDate(periodStart, start);
      final actualEnd = _minDate(periodEnd, effectiveEnd);

      if (!actualEnd.isBefore(actualStart)) {
        final weekNumber = _weekNumber(start, actualStart);
        periods.add(
          _buildPeriod(
            label: '第$weekNumber周',
            startDate: actualStart,
            endDate: actualEnd,
            checkedDates: checkedDates,
          ),
        );
      }

      periodStart = periodStart.add(const Duration(days: 7));
    }

    return periods;
  }

  static List<CheckinTrendPeriod> buildMonthlyTrends({
    required Set<String> checkedDates,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime today,
  }) {
    final start = _dateOnly(startDate);
    final effectiveEnd = _effectiveEndDate(endDate, today);
    if (effectiveEnd.isBefore(start)) {
      return [];
    }

    final periods = <CheckinTrendPeriod>[];
    var monthCursor = DateTime(start.year, start.month);

    while (!monthCursor.isAfter(effectiveEnd)) {
      final monthEnd = DateTime(monthCursor.year, monthCursor.month + 1, 0);
      final actualStart = _maxDate(monthCursor, start);
      final actualEnd = _minDate(monthEnd, effectiveEnd);

      if (!actualEnd.isBefore(actualStart)) {
        periods.add(
          _buildPeriod(
            label: '${monthCursor.month}月',
            startDate: actualStart,
            endDate: actualEnd,
            checkedDates: checkedDates,
          ),
        );
      }

      monthCursor = DateTime(monthCursor.year, monthCursor.month + 1);
    }

    return periods;
  }

  static CheckinTrendPeriod _buildPeriod({
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    required Set<String> checkedDates,
  }) {
    var checkedDays = 0;
    var cursor = startDate;

    while (!cursor.isAfter(endDate)) {
      if (checkedDates.contains(_dateToKey(cursor))) {
        checkedDays++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return CheckinTrendPeriod(
      label: label,
      startDate: startDate,
      endDate: endDate,
      checkedDays: checkedDays,
      totalDays: endDate.difference(startDate).inDays + 1,
    );
  }

  static DateTime _effectiveEndDate(DateTime endDate, DateTime today) {
    return _minDate(_dateOnly(endDate), _dateOnly(today));
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime _minDate(DateTime a, DateTime b) {
    return a.isBefore(b) ? a : b;
  }

  static DateTime _maxDate(DateTime a, DateTime b) {
    return a.isAfter(b) ? a : b;
  }

  static int _weekNumber(DateTime checkinStartDate, DateTime date) {
    final startOfFirstWeek = checkinStartDate.subtract(
      Duration(days: checkinStartDate.weekday - 1),
    );
    final startOfTargetWeek = date.subtract(Duration(days: date.weekday - 1));
    return (startOfTargetWeek.difference(startOfFirstWeek).inDays / 7).floor() +
        1;
  }

  static String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
