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

  /// 删除指定日期范围外的打卡记录
  Future<int> deleteRecordsOutsideRange(DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;

    final startKey = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endKey = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    // 删除开始日期之前和结束日期之后的记录
    final deletedCount = await db.delete(
      'checkin_records',
      where: 'date_key < ? OR date_key > ?',
      whereArgs: [startKey, endKey],
    );

    debugPrint('deleteRecordsOutsideRange: 删除了 $deletedCount 条范围外的记录');
    return deletedCount;
  }

  /// 删除所有打卡记录（用于重置）
  Future<int> deleteAllRecords() async {
    final db = await _dbHelper.database;
    final deletedCount = await db.delete('checkin_records');
    debugPrint('deleteAllRecords: 删除了 $deletedCount 条记录');
    return deletedCount;
  }

  /// 导出数据库中的全部记录
  Future<Map<String, dynamic>> exportAllData() async {
    final db = await _dbHelper.database;
    final records = await db.query(
      'checkin_records',
      orderBy: 'id ASC',
    );

    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'records': records,
    };
  }

  /// 用导入数据覆盖数据库中的全部记录
  Future<int> importAllData(Map<String, dynamic> jsonData) async {
    final rawRecords = jsonData['records'];
    if (rawRecords is! List) {
      throw const FormatException('备份文件格式不正确，缺少 records 列表');
    }

    final normalizedRecords = <Map<String, dynamic>>[];

    for (final item in rawRecords) {
      if (item is! Map) {
        throw const FormatException('备份文件格式不正确，存在非法记录');
      }

      final record = Map<String, dynamic>.from(item);
      final dateKey = record['date_key'];
      final operationTime = record['operation_time'];

      if (dateKey is! String || operationTime is! String) {
        throw const FormatException('备份文件格式不正确，记录字段缺失');
      }

      DateTime.parse(operationTime);

      final normalizedCheckedIn = switch (record['is_checked_in']) {
        bool value => value ? 1 : 0,
        int value when value == 0 || value == 1 => value,
        _ => throw const FormatException('备份文件格式不正确，is_checked_in 无效'),
      };

      final normalizedRecord = <String, dynamic>{
        'date_key': dateKey,
        'is_checked_in': normalizedCheckedIn,
        'operation_time': operationTime,
      };

      final id = record['id'];
      if (id is int) {
        normalizedRecord['id'] = id;
      }

      normalizedRecords.add(normalizedRecord);
    }

    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('checkin_records');

      if (normalizedRecords.isEmpty) {
        return;
      }

      final batch = txn.batch();
      for (final record in normalizedRecords) {
        batch.insert('checkin_records', record);
      }
      await batch.commit(noResult: true);
    });

    debugPrint('importAllData: 导入了 ${normalizedRecords.length} 条记录');
    return normalizedRecords.length;
  }
}
