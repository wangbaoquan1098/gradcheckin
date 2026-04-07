import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 数据库帮助类
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gradcheckin.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 打卡记录表
    await db.execute('''
      CREATE TABLE checkin_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date_key TEXT NOT NULL,
        is_checked_in INTEGER NOT NULL,
        operation_time TEXT NOT NULL
      )
    ''');
    
    // 创建索引
    await db.execute('CREATE INDEX idx_date_key ON checkin_records(date_key)');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
