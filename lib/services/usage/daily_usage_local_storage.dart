import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/daily_usage_stats.dart';

class DailyUsageLocalStorage {
  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'screen_therapist.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE daily_usage_stats (
            day_key TEXT PRIMARY KEY,
            screen_time_ms INTEGER NOT NULL,
            unlock_count INTEGER NOT NULL,
            late_night_usage_ms INTEGER NOT NULL,
            app_usage_json TEXT NOT NULL,
            updated_at_ms INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> upsert(DailyUsageStats stats) async {
    final db = await _database;
    await db.insert(
      'daily_usage_stats',
      stats.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DailyUsageStats?> getByDay(DateTime day) async {
    final db = await _database;
    final rows = await db.query(
      'daily_usage_stats',
      where: 'day_key = ?',
      whereArgs: [_dayKey(day)],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return DailyUsageStats.fromDbMap(rows.first);
  }

  Future<List<DailyUsageStats>> getLastNDays(
    DateTime dayInclusive,
    int days,
  ) async {
    final db = await _database;
    final start = dayInclusive.subtract(Duration(days: days - 1));
    final rows = await db.query(
      'daily_usage_stats',
      where: 'day_key >= ? AND day_key <= ?',
      whereArgs: [_dayKey(start), _dayKey(dayInclusive)],
      orderBy: 'day_key ASC',
    );

    return rows.map(DailyUsageStats.fromDbMap).toList();
  }

  static String _dayKey(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
