import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

/// 操作历史记录
class OperationRecord {
  final int? id;
  final String dateKey;
  final bool isCheckedIn;
  final DateTime operationTime;

  OperationRecord({
    this.id,
    required this.dateKey,
    required this.isCheckedIn,
    required this.operationTime,
  });

  Map<String, dynamic> toMap() => {
    'date_key': dateKey,
    'is_checked_in': isCheckedIn ? 1 : 0,
    'operation_time': operationTime.toIso8601String(),
  };

  factory OperationRecord.fromMap(Map<String, dynamic> map) {
    return OperationRecord(
      id: map['id'],
      dateKey: map['date_key'],
      isCheckedIn: map['is_checked_in'] == 1,
      operationTime: DateTime.parse(map['operation_time']),
    );
  }
}

/// 打卡仓库 - 使用SQLite数据库
class CheckinRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 获取所有已打卡的日期（当前状态）
  Future<Set<String>> getCheckedDates() async {
    final db = await _dbHelper.database;
    
    // 获取每个日期的最新记录
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT date_key, is_checked_in FROM checkin_records
      ORDER BY date_key, operation_time DESC
    ''');
    
    final seenDates = <String>{};
    final checkedDates = <String>{};
    
    for (final row in results) {
      final dateKey = row['date_key'] as String;
      if (!seenDates.contains(dateKey)) {
        seenDates.add(dateKey);
        if (row['is_checked_in'] == 1) {
          checkedDates.add(dateKey);
        }
      }
    }
    
    debugPrint('getCheckedDates: ${checkedDates.length} dates');
    return checkedDates;
  }

  /// 切换日期打卡状态
  Future<bool> toggleCheckin(String dateKey) async {
    final db = await _dbHelper.database;
    
    // 获取当前状态
    final currentStatus = await isCheckedIn(dateKey);
    final newStatus = !currentStatus;
    
    // 插入新记录
    final record = OperationRecord(
      dateKey: dateKey,
      isCheckedIn: newStatus,
      operationTime: DateTime.now(),
    );
    
    await db.insert('checkin_records', record.toMap());
    debugPrint('toggleCheckin: $dateKey -> $newStatus');
    
    return newStatus;
  }

  /// 检查日期是否已打卡
  Future<bool> isCheckedIn(String dateKey) async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'checkin_records',
      where: 'date_key = ?',
      whereArgs: [dateKey],
      orderBy: 'operation_time DESC',
      limit: 1,
    );
    
    if (results.isEmpty) return false;
    return results.first['is_checked_in'] == 1;
  }

  /// 获取操作历史记录（所有记录）
  Future<List<OperationRecord>> getHistory() async {
    final db = await _dbHelper.database;
    
    final results = await db.query(
      'checkin_records',
      orderBy: 'operation_time DESC',
    );
    
    return results.map((map) => OperationRecord.fromMap(map)).toList();
  }

  /// 获取指定月份的打卡记录
  Future<Map<String, bool>> getMonthCheckins(int year, int month) async {
    final db = await _dbHelper.database;
    final startKey = '$year-${month.toString().padLeft(2, '0')}-01';
    final endKey = '$year-${month.toString().padLeft(2, '0')}-31';
    
    final results = await db.query(
      'checkin_records',
      where: 'date_key >= ? AND date_key <= ?',
      whereArgs: [startKey, endKey],
      orderBy: 'date_key, operation_time DESC',
    );
    
    final seenDates = <String>{};
    final monthCheckins = <String, bool>{};
    
    for (final row in results) {
      final dateKey = row['date_key'] as String;
      if (!seenDates.contains(dateKey)) {
        seenDates.add(dateKey);
        monthCheckins[dateKey] = row['is_checked_in'] == 1;
      }
    }
    
    return monthCheckins;
  }
}
