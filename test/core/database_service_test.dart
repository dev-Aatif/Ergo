import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:convert';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
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
                  description TEXT NOT NULL DEFAULT ''
                )
              ''');
              await db.execute('''
                CREATE TABLE questions (
                  id TEXT PRIMARY KEY,
                  subject_id TEXT NOT NULL,
                  text TEXT NOT NULL,
                  options TEXT NOT NULL,
                  correct_index INTEGER NOT NULL
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
                  missed_question_ids TEXT NOT NULL
                )
              ''');
              await db.execute('''
                CREATE TABLE installed_dlc (
                  catalog_id TEXT PRIMARY KEY,
                  version REAL NOT NULL DEFAULT 1.0,
                  installed_at INTEGER NOT NULL
                )
              ''');
            }));
  });

  tearDown(() async {
    await db.close();
  });

  test('Database creates all required tables', () async {
    final tables = await db
        .query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    final tableNames = tables.map((t) => t['name'] as String).toSet();

    expect(
        tableNames,
        containsAll([
          'categories',
          'subjects',
          'questions',
          'quiz_attempts',
          'installed_dlc',
        ]));
  });

  test('Can insert and query categories', () async {
    await db.insert('categories', {
      'id': 'cat_test',
      'name': 'Test Category',
      'accent_color': '#FF0000',
      'icon_name': 'science',
    });

    final results =
        await db.query('categories', where: 'id = ?', whereArgs: ['cat_test']);

    expect(results.length, 1);
    expect(results[0]['name'], 'Test Category');
    expect(results[0]['icon_name'], 'science');
  });

  test('Subject description defaults to empty string', () async {
    await db.insert('categories', {
      'id': 'cat_1',
      'name': 'Cat',
      'accent_color': '#000',
      'icon_name': 'x',
    });

    await db.rawInsert(
        "INSERT INTO subjects (id, category_id, name) VALUES ('sub_1', 'cat_1', 'Test')");

    final results =
        await db.query('subjects', where: 'id = ?', whereArgs: ['sub_1']);

    expect(results[0]['description'], '');
  });

  test('Questions store options as JSON string', () async {
    final options = ['A', 'B', 'C', 'D'];
    await db.insert('questions', {
      'id': 'q_test',
      'subject_id': 'sub_1',
      'text': 'Test question?',
      'options': jsonEncode(options),
      'correct_index': 2,
    });

    final results =
        await db.query('questions', where: 'id = ?', whereArgs: ['q_test']);

    final storedOptions =
        jsonDecode(results[0]['options'] as String) as List<dynamic>;
    expect(storedOptions, ['A', 'B', 'C', 'D']);
    expect(results[0]['correct_index'], 2);
  });

  test('INSERT OR IGNORE prevents duplicate categories', () async {
    await db.insert('categories', {
      'id': 'cat_dup',
      'name': 'Original',
      'accent_color': '#111',
      'icon_name': 'x',
    });

    await db.execute(
        "INSERT OR IGNORE INTO categories (id, name, accent_color, icon_name) VALUES ('cat_dup', 'Duplicate', '#222', 'y')");

    final results =
        await db.query('categories', where: 'id = ?', whereArgs: ['cat_dup']);

    expect(results.length, 1);
    expect(results[0]['name'], 'Original'); // first insert wins
  });

  test('installed_dlc tracks catalog items', () async {
    await db.insert('installed_dlc', {
      'catalog_id': 'dlc_001',
      'version': 1.0,
      'installed_at': DateTime.now().millisecondsSinceEpoch,
    });

    final results = await db.query('installed_dlc');

    expect(results.length, 1);
    expect(results[0]['catalog_id'], 'dlc_001');
    expect(results[0]['version'], 1.0);
  });

  test('installed_dlc upserts on conflict', () async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('installed_dlc', {
      'catalog_id': 'dlc_001',
      'version': 1.0,
      'installed_at': now,
    });

    // Update same catalog_id with new version
    await db.insert(
      'installed_dlc',
      {
        'catalog_id': 'dlc_001',
        'version': 2.0,
        'installed_at': now + 1000,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final results = await db.query('installed_dlc');

    expect(results.length, 1);
    expect(results[0]['version'], 2.0);
  });

  test('DLC merge via INSERT OR IGNORE preserves existing data', () async {
    // Seed main DB with existing category
    await db.insert('categories', {
      'id': 'cat_main',
      'name': 'Main Cat',
      'accent_color': '#000',
      'icon_name': 'x',
    });

    // Simulate the merge logic: INSERT OR IGNORE skips existing IDs
    await db.execute(
        "INSERT OR IGNORE INTO categories (id, name, accent_color, icon_name) VALUES ('cat_main', 'Should Be Ignored', '#999', 'z')");
    await db.execute(
        "INSERT OR IGNORE INTO categories (id, name, accent_color, icon_name) VALUES ('cat_dlc', 'DLC Cat', '#FFF', 'y')");

    final cats = await db.query('categories', orderBy: 'id');
    expect(cats.length, 2);
    // Original preserved
    expect(cats.firstWhere((c) => c['id'] == 'cat_main')['name'], 'Main Cat');
    // New DLC added
    expect(cats.firstWhere((c) => c['id'] == 'cat_dlc')['name'], 'DLC Cat');
  });

  test('Quiz attempts store and retrieve correctly', () async {
    await db.insert('quiz_attempts', {
      'id': 'attempt_1',
      'category_id': 'cat_1',
      'date': DateTime.now().millisecondsSinceEpoch,
      'score': 8,
      'total_questions': 10,
      'time_taken': 120,
      'missed_question_ids': jsonEncode(['q1', 'q2']),
    });

    final results = await db.query('quiz_attempts');

    expect(results.length, 1);
    expect(results[0]['score'], 8);

    final missed =
        jsonDecode(results[0]['missed_question_ids'] as String) as List;
    expect(missed.length, 2);
    expect(missed, contains('q1'));
  });
}
