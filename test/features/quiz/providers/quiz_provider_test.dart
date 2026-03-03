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

  List<Map<String, dynamic>> threeQuestions() => [
        {
          'id': 'q1',
          'subject_id': 'subj_1',
          'text': 'What is 2+2?',
          'options': '["3", "4", "5"]',
          'correct_index': 1
        },
        {
          'id': 'q2',
          'subject_id': 'subj_1',
          'text': 'Capital of France?',
          'options': '["Berlin", "Paris", "London"]',
          'correct_index': 1
        },
        {
          'id': 'q3',
          'subject_id': 'subj_1',
          'text': 'Largest planet?',
          'options': '["Mars", "Jupiter", "Saturn"]',
          'correct_index': 1
        },
      ];

  // ── Initialization Tests ──

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

  test('Quiz starts with score 0 and at index 0', () async {
    stubQuestions(threeQuestions());

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
    expect(state.isFinished, isFalse);
    expect(state.missedQuestionIds, isEmpty);
    expect(state.questions.length, 3);

    subscription.close();
  });

  // ── Quiz Config Tests ──

  test('Default config uses plotArmor difficulty', () {
    const config = QuizConfig();
    expect(config.difficulty, Difficulty.plotArmor);
    expect(config.maxLives, -1); // unlimited
  });

  test('Almost Him config has 3 lives', () {
    const config = QuizConfig(difficulty: Difficulty.almostHim);
    expect(config.maxLives, 3);
  });

  test('Canon Event config has 1 life', () {
    const config = QuizConfig(difficulty: Difficulty.canonEvent);
    expect(config.maxLives, 1);
  });

  test('Snail speed has no timer', () {
    const config = QuizConfig(speed: Speed.snail);
    expect(config.timePerQuestion, 0);
  });

  test('Crunch Time speed has 15s timer', () {
    const config = QuizConfig(speed: Speed.crunchTime);
    expect(config.timePerQuestion, 15);
  });

  test('Panic speed has 7s timer', () {
    const config = QuizConfig(speed: Speed.panic);
    expect(config.timePerQuestion, 7);
  });

  // ── Game Logic Tests (Answering) ──

  test('Correct answer increments score', () async {
    stubQuestions(threeQuestions());

    // Stub the insert for saving attempts
    when(() => mockDb.insert(any(), any(),
            conflictAlgorithm: any(named: 'conflictAlgorithm')))
        .thenAnswer((_) async => 1);

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
        audioServiceProvider.overrideWithValue(mockAudioService),
      ],
    );

    final subscription = container.listen(quizProvider('subj_1'), (_, __) {});
    await container.read(quizProvider('subj_1').future);

    // Get the question's correct index after shuffling
    final initialState = await container.read(quizProvider('subj_1').future);
    final correctIdx = initialState.questions[0].correctIndex;

    container.read(quizProvider('subj_1').notifier).answerQuestion(correctIdx);

    // Wait for state to update
    await Future.delayed(const Duration(milliseconds: 100));

    final updatedState = await container.read(quizProvider('subj_1').future);

    expect(updatedState.score, 1);
    expect(updatedState.currentIndex, 1);
    expect(updatedState.missedQuestionIds, isEmpty);

    subscription.close();
  });

  test(
      'Wrong answer adds to missed list but does not decrement lives in Plot Armor',
      () async {
    stubQuestions(threeQuestions());

    when(() => mockDb.insert(any(), any(),
            conflictAlgorithm: any(named: 'conflictAlgorithm')))
        .thenAnswer((_) async => 1);

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
        audioServiceProvider.overrideWithValue(mockAudioService),
        quizConfigProvider.overrideWith(
            (ref) => const QuizConfig(difficulty: Difficulty.plotArmor)),
      ],
    );

    final subscription = container.listen(quizProvider('subj_1'), (_, __) {});
    final initialState = await container.read(quizProvider('subj_1').future);

    // Answer with wrong index (any index != correct)
    final wrongIdx = (initialState.questions[0].correctIndex + 1) %
        initialState.questions[0].options.length;

    container.read(quizProvider('subj_1').notifier).answerQuestion(wrongIdx);

    await Future.delayed(const Duration(milliseconds: 100));

    final state = await container.read(quizProvider('subj_1').future);

    expect(state.score, 0);
    expect(state.missedQuestionIds.length, 1);
    // Plot Armor: quiz should not be finished after one wrong answer
    expect(state.isGameOver, isFalse);

    subscription.close();
  });

  test('Timeout is treated as wrong answer', () async {
    stubQuestions(threeQuestions());

    when(() => mockDb.insert(any(), any(),
            conflictAlgorithm: any(named: 'conflictAlgorithm')))
        .thenAnswer((_) async => 1);

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
        audioServiceProvider.overrideWithValue(mockAudioService),
      ],
    );

    final subscription = container.listen(quizProvider('subj_1'), (_, __) {});
    await container.read(quizProvider('subj_1').future);

    container.read(quizProvider('subj_1').notifier).timeOut();

    await Future.delayed(const Duration(milliseconds: 100));

    final state = await container.read(quizProvider('subj_1').future);

    expect(state.score, 0);
    expect(state.currentIndex, 1);
    expect(state.missedQuestionIds.length, 1);

    subscription.close();
  });

  // ── Difficulty Tests ──

  test('Canon Event: game over on first wrong answer', () async {
    stubQuestions(threeQuestions());

    when(() => mockDb.insert(any(), any(),
            conflictAlgorithm: any(named: 'conflictAlgorithm')))
        .thenAnswer((_) async => 1);

    final container = TestUtils.createContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(mockDbService),
        audioServiceProvider.overrideWithValue(mockAudioService),
        quizConfigProvider.overrideWith(
            (ref) => const QuizConfig(difficulty: Difficulty.canonEvent)),
      ],
    );

    final subscription = container.listen(quizProvider('subj_1'), (_, __) {});
    final initialState = await container.read(quizProvider('subj_1').future);

    // Verify 1 life
    expect(initialState.livesRemaining, 1);

    // Wrong answer
    final wrongIdx = (initialState.questions[0].correctIndex + 1) %
        initialState.questions[0].options.length;

    container.read(quizProvider('subj_1').notifier).answerQuestion(wrongIdx);

    await Future.delayed(const Duration(milliseconds: 100));

    final state = await container.read(quizProvider('subj_1').future);

    expect(state.isGameOver, isTrue);
    expect(state.isFinished, isTrue);
    expect(state.livesRemaining, 0);

    subscription.close();
  });
}
