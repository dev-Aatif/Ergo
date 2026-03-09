import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ergo/features/home/providers/streak_provider.dart';
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
            }));

    mockDbService = MockDatabaseService();
    when(() => mockDbService.db).thenReturn(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertAttempt(DateTime date, {String id = ''}) async {
    final actualId = id.isEmpty ? date.millisecondsSinceEpoch.toString() : id;
    await db.insert('quiz_attempts', {
      'id': actualId,
      'category_id': 'test',
      'date': date.millisecondsSinceEpoch,
      'score': 8,
      'total_questions': 10,
      'time_taken': 60,
      'missed_question_ids': '[]',
    });
  }

  test('Streak is 0 when database is completely empty', () async {
    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
      ],
    );
    final streak = await container.read(streakProvider.future);
    expect(streak.currentStreak, 0);
  });

  test('Streak is 1 for a single attempt today', () async {
    await insertAttempt(DateTime.now());

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
      ],
    );
    final streak = await container.read(streakProvider.future);
    expect(streak.currentStreak, 1);
  });

  test('Streak is 1 when only yesterday has attempts', () async {
    await insertAttempt(DateTime.now().subtract(const Duration(days: 1)));

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
      ],
    );
    final streak = await container.read(streakProvider.future);
    expect(streak.currentStreak, 1);
  });

  test('Streak counts 3 continuous days starting today', () async {
    final now = DateTime.now();
    await insertAttempt(now, id: 'today');
    await insertAttempt(now.subtract(const Duration(days: 1)), id: 'yesterday');
    await insertAttempt(now.subtract(const Duration(days: 2)),
        id: 'twoDaysAgo');

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
      ],
    );
    final streak = await container.read(streakProvider.future);
    expect(streak.currentStreak, 3);
  });

  test('Streak resets when there is a gap', () async {
    final now = DateTime.now();
    await insertAttempt(now, id: 'today');
    // Skip yesterday
    await insertAttempt(now.subtract(const Duration(days: 2)),
        id: 'twoDaysAgo');

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
      ],
    );
    final streak = await container.read(streakProvider.future);
    expect(streak.currentStreak, 1); // Only today counts
  });

  test('Streak is 0 if last attempt was 2+ days ago', () async {
    await insertAttempt(DateTime.now().subtract(const Duration(days: 3)));

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
      ],
    );
    final streak = await container.read(streakProvider.future);
    expect(streak.currentStreak, 0);
  });

  test('Multiple attempts on same day count as 1 streak day', () async {
    final now = DateTime.now();
    await insertAttempt(now, id: 'attempt1');
    await insertAttempt(now, id: 'attempt2');
    await insertAttempt(now, id: 'attempt3');

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
      ],
    );
    final streak = await container.read(streakProvider.future);
    expect(streak.currentStreak, 1);
  });

  test('Long streak of 7 days', () async {
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      await insertAttempt(now.subtract(Duration(days: i)), id: 'day_$i');
    }

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
      ],
    );
    final streak = await container.read(streakProvider.future);
    expect(streak.currentStreak, 7);
  });
}
