import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/daily_intake.dart';

class HistoryRepository {
  Database? _db;

  Future<void> init() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'smart_bottle.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE daily_intake(
            date TEXT PRIMARY KEY,
            drank_liters REAL NOT NULL DEFAULT 0,
            used INTEGER NOT NULL DEFAULT 0,
            goal_achieved INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE synced_readings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp_ms INTEGER NOT NULL,
            level_percent INTEGER NOT NULL,
            temperature_c REAL NOT NULL,
            tds_ppm INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('HistoryRepository not initialized');
    }
    return db;
  }

  String _dayKey(DateTime date) => DateTime(
    date.year,
    date.month,
    date.day,
  ).toIso8601String().split('T').first;

  Future<void> addSyncedReading({
    required DateTime timestamp,
    required int levelPercent,
    required double temperatureC,
    required int tdsPpm,
  }) async {
    await _database.insert('synced_readings', {
      'timestamp_ms': timestamp.millisecondsSinceEpoch,
      'level_percent': levelPercent,
      'temperature_c': temperatureC,
      'tds_ppm': tdsPpm,
    });
    await markUsedDay(timestamp);
  }

  Future<void> markUsedDay(DateTime date) async {
    final key = _dayKey(date);
    await _database.insert('daily_intake', {
      'date': key,
      'drank_liters': 0,
      'used': 1,
      'goal_achieved': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await _database.update(
      'daily_intake',
      {'used': 1},
      where: 'date = ?',
      whereArgs: [key],
    );
  }

  Future<double> addDrinking(
    DateTime date,
    double liters,
    double goalLiters,
  ) async {
    final key = _dayKey(date);
    await _database.insert('daily_intake', {
      'date': key,
      'drank_liters': 0,
      'used': 1,
      'goal_achieved': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final current = await _database.query(
      'daily_intake',
      columns: ['drank_liters'],
      where: 'date = ?',
      whereArgs: [key],
      limit: 1,
    );

    final currentLiters = current.isEmpty
        ? 0.0
        : (current.first['drank_liters'] as num).toDouble();
    final updated = currentLiters + liters;
    await _database.update(
      'daily_intake',
      {
        'drank_liters': updated,
        'goal_achieved': updated >= goalLiters ? 1 : 0,
        'used': 1,
      },
      where: 'date = ?',
      whereArgs: [key],
    );

    return updated;
  }

  Future<double> getTodayDrank(DateTime today) async {
    final key = _dayKey(today);
    final rows = await _database.query(
      'daily_intake',
      columns: ['drank_liters'],
      where: 'date = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (rows.isEmpty) return 0;
    return (rows.first['drank_liters'] as num).toDouble();
  }

  Future<List<DailyIntake>> fetchSince(DateTime fromInclusive) async {
    final rows = await _database.query(
      'daily_intake',
      where: 'date >= ?',
      whereArgs: [_dayKey(fromInclusive)],
      orderBy: 'date ASC',
    );
    return rows.map((row) => DailyIntake.fromMap(row)).toList();
  }

  Future<List<DailyIntake>> fetchLastDays(int days) async {
    final start = DateTime.now().subtract(Duration(days: days - 1));
    final list = await fetchSince(DateTime(start.year, start.month, start.day));
    final indexed = {
      for (final item in list)
        item.date.toIso8601String().split('T').first: item,
    };

    final filled = <DailyIntake>[];
    for (var i = 0; i < days; i++) {
      final day = DateTime.now().subtract(Duration(days: days - i - 1));
      final key = DateTime(
        day.year,
        day.month,
        day.day,
      ).toIso8601String().split('T').first;
      filled.add(
        indexed[key] ??
            DailyIntake(
              date: DateTime(day.year, day.month, day.day),
              drankLiters: 0,
              used: false,
              goalAchieved: false,
            ),
      );
    }
    return filled;
  }

  ReportSummary computeSummary(List<DailyIntake> items, double goalLiters) {
    final used = items.where((e) => e.used).toList();
    final total = used.fold<double>(0, (sum, e) => sum + e.drankLiters);
    final usedDays = used.length;
    final average = usedDays == 0 ? 0.0 : total / usedDays;
    final achieved = used.where((e) => e.drankLiters >= goalLiters).length;

    return ReportSummary(
      averagePerUsedDay: average,
      goalAchievedDays: achieved,
      usedDays: usedDays,
      totalDrank: total,
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
