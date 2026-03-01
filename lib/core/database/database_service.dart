import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'seed_data.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService must be overridden in main.dart');
});

class DatabaseService {
  static Database? _db;

  static const String _dbName = 'ergo_main.db';
  static const int _dbVersion = 1;

  Database get db {
    if (_db == null) throw Exception("Database not initialized");
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    // For MVP seed data: If the DB doesn't exist, we can potentially copy a pre-populated DB from assets.
    // Right now, we create empty tables.
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        accent_color TEXT NOT NULL,
        icon_name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subjects (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        subject_id TEXT NOT NULL,
        text TEXT NOT NULL,
        options TEXT NOT NULL,
        correct_index INTEGER NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_attempts (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        date INTEGER NOT NULL,
        score INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        time_taken INTEGER NOT NULL,
        missed_question_ids TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Hydrate the database with seed data
    await insertSeedData(db);
  }

  /// The magic DLC Engine: Attaches another SQLite DB and merges its contents into the main DB.
  Future<void> mergeDlcDatabase(String dlcDbPath) async {
    if (_db == null) throw Exception("Main database not initialized");

    try {
      await db.execute("ATTACH DATABASE '$dlcDbPath' AS dlc");

      // Perform the merge inside a transaction for speed and safety
      await db.transaction((txn) async {
        await txn.execute(
            "INSERT OR IGNORE INTO main.categories SELECT * FROM dlc.categories");
        await txn.execute(
            "INSERT OR IGNORE INTO main.subjects SELECT * FROM dlc.subjects");
        await txn.execute(
            "INSERT OR IGNORE INTO main.questions SELECT * FROM dlc.questions");
      });
    } finally {
      // Always detach safely
      await db.execute("DETACH DATABASE dlc");
    }
  }
}
