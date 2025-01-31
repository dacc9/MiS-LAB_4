import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/exam_event_model.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'exam_events.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE events(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            dateTime TEXT,
            location TEXT,
            latitude REAL,
            longitude REAL
          )
        ''');
      },
    );
  }

  Future<int> insertEvent(ExamEvent event) async {
    final db = await database;
    return await db.insert('events', event.toMap());
  }

  Future<List<ExamEvent>> getEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (i) => ExamEvent.fromMap(maps[i]));
  }

  Future<List<ExamEvent>> getEventsForDay(DateTime day) async {
    final db = await database;
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'dateTime BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    return List.generate(maps.length, (i) => ExamEvent.fromMap(maps[i]));
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}