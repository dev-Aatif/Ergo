import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'seed_data.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService must be overridden in main.dart');
});

class DatabaseService {
  Database? _db;

  static const String _dbName = 'ergo_main.db';
  static const int _dbVersion = 2;

  Database get db {
    if (_db == null) throw Exception("Database not initialized");
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// For testing: allows injecting an in-memory database
  void setDatabase(Database database) {
    _db = database;
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
        description TEXT NOT NULL DEFAULT '',
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

    await db.execute('''
      CREATE TABLE installed_dlc (
        catalog_id TEXT PRIMARY KEY,
        version REAL NOT NULL DEFAULT 1.0,
        installed_at INTEGER NOT NULL
      )
    ''');

    // Hydrate the database with seed data
    await insertSeedData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration v1 → v2: add installed_dlc table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS installed_dlc (
          catalog_id TEXT PRIMARY KEY,
          version REAL NOT NULL DEFAULT 1.0,
          installed_at INTEGER NOT NULL
        )
      ''');
      // Migration v1 → v2: add description column to subjects
      await db.execute(
          "ALTER TABLE subjects ADD COLUMN description TEXT NOT NULL DEFAULT ''");
    }
  }

  /// The magic DLC Engine: Attaches another SQLite DB and merges its contents into the main DB.
  Future<void> mergeDlcDatabase(String dlcDbPath) async {
    if (_db == null) throw Exception("Main database not initialized");

    // Sanitize path: replace single quotes to prevent SQL injection
    final safePath = dlcDbPath.replaceAll("'", "''");

    try {
      await db.execute("ATTACH DATABASE '$safePath' AS dlc");

      // Perform the merge inside a transaction for speed and safety
      await db.transaction((txn) async {
        await txn.execute(
            "INSERT OR IGNORE INTO main.categories (id, name, accent_color, icon_name) SELECT id, name, accent_color, icon_name FROM dlc.categories");
        await txn.execute(
            "INSERT OR IGNORE INTO main.subjects (id, category_id, name, description) SELECT id, category_id, name, description FROM dlc.subjects");
        await txn.execute(
            "INSERT OR IGNORE INTO main.questions (id, subject_id, text, options, correct_index) SELECT id, subject_id, text, options, correct_index FROM dlc.questions");
      });
    } finally {
      // Always detach safely
      await db.execute("DETACH DATABASE dlc");
    }
  }

  /// Tracks that a DLC catalog item was installed
  Future<void> markDlcInstalled(String catalogId, double version) async {
    await db.insert(
      'installed_dlc',
      {
        'catalog_id': catalogId,
        'version': version,
        'installed_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns the set of installed DLC catalog IDs
  Future<Set<String>> getInstalledDlcIds() async {
    final maps = await db.query('installed_dlc');
    return maps.map((m) => m['catalog_id'] as String).toSet();
  }
}
