/// 趋势聚合方式
enum TrendGrouping { weekly, monthly }

/// 单个趋势周期的数据
class CheckinTrendPeriod {
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final int checkedDays;
  final int totalDays;

  const CheckinTrendPeriod({
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.checkedDays,
    required this.totalDays,
  });

  double get rate => totalDays == 0 ? 0 : checkedDays / totalDays;
}
