import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ergo/features/history/providers/history_provider.dart';
import 'package:ergo/core/database/database_service.dart';

import '../../../test_utils.dart';

void main() {
  late Database db;
  late MockDatabaseService mockDbService;

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
                );
              ''');
              await db.execute('''
                CREATE TABLE subjects (
                  id TEXT PRIMARY KEY,
                  category_id TEXT NOT NULL,
                  name TEXT NOT NULL,
                  description TEXT NOT NULL DEFAULT ''
                );
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
                );
              ''');
              await db.execute('''
                CREATE TABLE answer_log (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  attempt_id TEXT NOT NULL,
                  question_id TEXT NOT NULL,
                  question_index INTEGER NOT NULL,
                  selected_index INTEGER NOT NULL,
                  correct_index INTEGER NOT NULL,
                  is_correct INTEGER NOT NULL,
                  time_ms INTEGER NOT NULL,
                  created_at INTEGER NOT NULL
                );
              ''');
              await db.insert('categories', {
                'id': 'cat_1',
                'name': 'History',
                'accent_color': '#FF5722',
                'icon_name': 'auto_stories',
              });
              await db.insert('categories', {
                'id': 'cat_2',
                'name': 'Science',
                'accent_color': '#4CAF50',
                'icon_name': 'science',
              });
            }));

    mockDbService = MockDatabaseService();
    when(() => mockDbService.db).thenReturn(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertAttempt({
    required String id,
    required String categoryId,
    required DateTime date,
    int score = 8,
    int total = 10,
    int time = 60,
  }) async {
    await db.insert('quiz_attempts', {
      'id': id,
      'category_id': categoryId,
      'date': date.millisecondsSinceEpoch,
      'score': score,
      'total_questions': total,
      'time_taken': time,
      'missed_question_ids': '[]',
    });
  }

  test('Returns empty stats with no attempts', () async {
    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final stats = await container.read(historyProvider.future);

    expect(stats.totalQuizzesTaken, 0);
    expect(stats.globalAccuracy, 0.0);
    expect(stats.recentAttempts, isEmpty);
    expect(stats.heatMapData, isEmpty);
    expect(stats.categoryBreakdown, isEmpty);
  });

  test('Calculates global accuracy correctly', () async {
    await insertAttempt(
        id: 'a1',
        categoryId: 'cat_1',
        date: DateTime.now(),
        score: 7,
        total: 10);
    await insertAttempt(
        id: 'a2',
        categoryId: 'cat_1',
        date: DateTime.now(),
        score: 3,
        total: 10);

    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final stats = await container.read(historyProvider.future);

    expect(stats.totalQuizzesTaken, 2);
    expect(stats.totalQuestionsAnswered, 20);
    expect(stats.globalAccuracy, 0.5); // 10/20
  });

  test('Tracks best score percentage', () async {
    await insertAttempt(
        id: 'a1',
        categoryId: 'cat_1',
        date: DateTime.now(),
        score: 5,
        total: 10);
    await insertAttempt(
        id: 'a2',
        categoryId: 'cat_1',
        date: DateTime.now(),
        score: 9,
        total: 10);

    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final stats = await container.read(historyProvider.future);

    expect(stats.bestScorePercentage, 0.9); // 9/10
  });

  test('Groups heatmap data by day', () async {
    final today = DateTime.now();
    await insertAttempt(id: 'a1', categoryId: 'cat_1', date: today);
    await insertAttempt(id: 'a2', categoryId: 'cat_1', date: today);

    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final stats = await container.read(historyProvider.future);

    final todayKey = DateTime(today.year, today.month, today.day);
    expect(stats.heatMapData[todayKey], 2);
  });

  test('Produces per-category breakdown', () async {
    await insertAttempt(
        id: 'a1',
        categoryId: 'cat_1',
        date: DateTime.now(),
        score: 8,
        total: 10);
    await insertAttempt(
        id: 'a2',
        categoryId: 'cat_2',
        date: DateTime.now(),
        score: 6,
        total: 10);

    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final stats = await container.read(historyProvider.future);

    expect(stats.categoryBreakdown.length, 2);
    expect(stats.categoryBreakdown['cat_1']!.categoryName, 'History');
    expect(stats.categoryBreakdown['cat_2']!.categoryName, 'Science');
    expect(stats.categoryBreakdown['cat_1']!.accuracy, 0.8);
    expect(stats.categoryBreakdown['cat_2']!.accuracy, 0.6);
  });

  test('Moving average has correct length', () async {
    for (int i = 0; i < 5; i++) {
      await insertAttempt(
        id: 'a_$i',
        categoryId: 'cat_1',
        date: DateTime.now().subtract(Duration(days: i)),
        score: 5 + i,
        total: 10,
      );
    }

    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final stats = await container.read(historyProvider.future);

    expect(stats.movingAverageScoring.length, 5);
    expect(stats.recentAttempts.length, 5);
  });
}
