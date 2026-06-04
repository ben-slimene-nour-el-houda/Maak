import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'maak_feedback.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE feedback (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            office TEXT,
            day TEXT,
            time_slot_index INTEGER,
            rating INTEGER,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  // Save one feedback entry
  static Future<void> saveFeedback(FeedbackModel feedback) async {
    final db = await database;
    await db.insert('feedback', feedback.toMap());
  }

  // Get average rating for a specific office + day + slot
  // Returns null if no feedback exists yet
  static Future<double?> getAverageRating(
    String office, String day, int slotIndex) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT AVG(rating) as avg FROM feedback
      WHERE office = ? AND day = ? AND time_slot_index = ?
    ''', [office, day, slotIndex]);
    final avg = result.first['avg'];
    return avg == null ? null : (avg as num).toDouble();
  }

  // Get count of feedback entries for a slot (for "based on X visits" badge)
  static Future<int> getFeedbackCount(
    String office, String day, int slotIndex) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM feedback
      WHERE office = ? AND day = ? AND time_slot_index = ?
    ''', [office, day, slotIndex]);
    return (result.first['count'] as num).toInt();
  }
}
