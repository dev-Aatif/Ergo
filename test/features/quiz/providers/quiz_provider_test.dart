import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ergo/features/quiz/providers/quiz_provider.dart';
import 'package:ergo/core/database/database_service.dart';
import 'package:ergo/core/audio/audio_service.dart';

import '../../../test_utils.dart';

void main() {
  late MockDatabaseService mockDbService;
  late MockDatabase mockDb;
  late MockAudioService mockAudioService;

  setUp(() {
    mockDbService = MockDatabaseService();
    mockDb = MockDatabase();
    mockAudioService = MockAudioService();

    when(() => mockDbService.db).thenReturn(mockDb);

    when(() => mockAudioService.playCorrect())
        .thenAnswer((_) => Future.value());
    when(() => mockAudioService.playIncorrect())
        .thenAnswer((_) => Future.value());
    when(() => mockAudioService.playLevelUp())
        .thenAnswer((_) => Future.value());
    when(() => mockAudioService.playMagicalStreak())
        .thenAnswer((_) => Future.value());
    when(() => mockAudioService.playClick()).thenAnswer((_) => Future.value());
  });

  void stubQuestions(List<Map<String, dynamic>> questions) {
    when(() => mockDb.query('subjects',
            where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
        .thenAnswer((_) async => [
              {
                'id': 'subj_1',
                'category_id': 'cat_1',
                'name': 'Test Subj',
                'description': 'desc'
              }
            ]);

    when(() => mockDb.query('questions',
        where: any(named: 'where'),
        whereArgs: any(named: 'whereArgs'))).thenAnswer((_) async => questions);
  }

  test('Quiz initializes correctly from database', () async {
    stubQuestions([
      {
        'id': 'q1',
        'subject_id': 'subj_1',
        'text': 'What is 2+2?',
        'options': '["3", "4", "5"]',
        'correct_index': 1
      }
    ]);

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
        audioServiceProvider.overrideWithValue(mockAudioService),
      ],
    );

    final subscription = container.listen(quizProvider('subj_1'), (_, __) {});
    final state = await container.read(quizProvider('subj_1').future);

    expect(state.isLoading, isFalse);
    expect(state.questions.length, 1);
    expect(state.questions.first.text, 'What is 2+2?');

    subscription.close();
  });

  test('Quiz handles empty question list gracefully', () async {
    stubQuestions([]);

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
        audioServiceProvider.overrideWithValue(mockAudioService),
      ],
    );

    final subscription = container.listen(quizProvider('subj_1'), (_, __) {});
    final state = await container.read(quizProvider('subj_1').future);

    expect(state.questions, isEmpty);
    expect(state.isFinished, isFalse);

    subscription.close();
  });

  test('Quiz initializes with multiple questions and correct state', () async {
    stubQuestions([
      {
        'id': 'q1',
        'subject_id': 'subj_1',
        'text': 'Q1',
        'options': '["A", "B", "C"]',
        'correct_index': 0
      },
      {
        'id': 'q2',
        'subject_id': 'subj_1',
        'text': 'Q2',
        'options': '["X", "Y", "Z"]',
        'correct_index': 2
      },
      {
        'id': 'q3',
        'subject_id': 'subj_1',
        'text': 'Q3',
        'options': '["1", "2", "3"]',
        'correct_index': 1
      },
    ]);

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
        audioServiceProvider.overrideWithValue(mockAudioService),
      ],
    );

    final subscription = container.listen(quizProvider('subj_1'), (_, __) {});
    final state = await container.read(quizProvider('subj_1').future);

    expect(state.questions.length, 3);
    expect(state.currentIndex, 0);
    expect(state.score, 0);
    expect(state.isFinished, isFalse);
    expect(state.missedQuestionIds, isEmpty);

    subscription.close();
  });

  test('Quiz starts with score 0 and at index 0', () async {
    stubQuestions([
      {
        'id': 'q1',
        'subject_id': 'subj_1',
        'text': 'Q1',
        'options': '["A", "B"]',
        'correct_index': 0
      },
    ]);

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
        audioServiceProvider.overrideWithValue(mockAudioService),
      ],
    );

    final subscription = container.listen(quizProvider('subj_1'), (_, __) {});
    final state = await container.read(quizProvider('subj_1').future);

    expect(state.score, 0);
    expect(state.currentIndex, 0);
    expect(state.isLoading, isFalse);

    subscription.close();
  });
}
