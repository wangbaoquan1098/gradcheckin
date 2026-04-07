/// 打卡记录模型
class CheckinRecord {
  final DateTime date;
  final bool isCheckedIn;
  final DateTime operationTime; // 操作时间
  final String operationType; // 操作类型: 'checkin' 或 'cancel'

  CheckinRecord({
    required this.date,
    required this.isCheckedIn,
    required this.operationTime,
    required this.operationType,
  });

  /// 生成日期键名 (格式: yyyy-MM-dd)
  String get dateKey => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'isCheckedIn': isCheckedIn,
    'operationTime': operationTime.toIso8601String(),
    'operationType': operationType,
  };

  factory CheckinRecord.fromJson(Map<String, dynamic> json) {
    return CheckinRecord(
      date: DateTime.parse(json['date']),
      isCheckedIn: json['isCheckedIn'] ?? false,
      operationTime: DateTime.parse(json['operationTime']),
      operationType: json['operationType'] ?? 'checkin',
    );
  }
}
