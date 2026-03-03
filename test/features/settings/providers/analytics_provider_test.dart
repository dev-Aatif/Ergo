import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ergo/features/settings/providers/analytics_provider.dart';
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

  Future<void> insertAttempt({
    required String id,
    int score = 8,
    int total = 10,
    int timeTaken = 60,
  }) async {
    await db.insert('quiz_attempts', {
      'id': id,
      'category_id': 'cat_1',
      'date': DateTime.now().millisecondsSinceEpoch,
      'score': score,
      'total_questions': total,
      'time_taken': timeTaken,
      'missed_question_ids': '[]',
    });
  }

  test('Returns zero stats with no attempts', () async {
    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final analytics = await container.read(analyticsProvider.future);

    expect(analytics.totalQuizzes, 0);
    expect(analytics.averageAccuracy, 0.0);
    expect(analytics.totalTimeSpentSeconds, 0);
  });

  test('Counts total quizzes correctly', () async {
    await insertAttempt(id: 'a1');
    await insertAttempt(id: 'a2');
    await insertAttempt(id: 'a3');

    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final analytics = await container.read(analyticsProvider.future);

    expect(analytics.totalQuizzes, 3);
  });

  test('Calculates accuracy correctly', () async {
    await insertAttempt(id: 'a1', score: 7, total: 10);
    await insertAttempt(id: 'a2', score: 3, total: 10);

    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final analytics = await container.read(analyticsProvider.future);

    // (7+3)/(10+10) = 0.5 → 50%
    expect(analytics.averageAccuracy, 50.0);
  });

  test('Aggregates time spent correctly', () async {
    await insertAttempt(id: 'a1', timeTaken: 120);
    await insertAttempt(id: 'a2', timeTaken: 60);
    await insertAttempt(id: 'a3', timeTaken: 30);

    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final analytics = await container.read(analyticsProvider.future);

    expect(analytics.totalTimeSpentSeconds, 210); // 120+60+30
  });

  test('Perfect scores result in 100% accuracy', () async {
    await insertAttempt(id: 'a1', score: 10, total: 10);
    await insertAttempt(id: 'a2', score: 5, total: 5);

    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final analytics = await container.read(analyticsProvider.future);

    expect(analytics.averageAccuracy, 100.0);
  });
}
