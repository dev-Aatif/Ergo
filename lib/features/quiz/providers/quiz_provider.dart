import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/question.dart';
import '../../../core/models/quiz_attempt.dart';
import '../../../core/audio/audio_service.dart';
import '../../home/providers/streak_provider.dart';
import '../../history/providers/history_provider.dart';

// ── Game Mode Enums ──

enum Difficulty {
  plotArmor, // Unlimited retries
  almostHim, // 3 lives
  canonEvent, // No lifeline
}

enum Speed {
  snail, // No timer
  crunchTime, // 15 seconds
  panic, // 7 seconds
}

// ── Quiz Configuration ──

class QuizConfig {
  final int? questionLimit; // null = all
  final Difficulty difficulty;
  final Speed speed;

  const QuizConfig({
    this.questionLimit,
    this.difficulty = Difficulty.plotArmor,
    this.speed = Speed.snail,
  });

  int get timePerQuestion {
    switch (speed) {
      case Speed.snail:
        return 0; // No timer
      case Speed.crunchTime:
        return 15;
      case Speed.panic:
        return 7;
    }
  }

  int get maxLives {
    switch (difficulty) {
      case Difficulty.plotArmor:
        return -1; // Unlimited
      case Difficulty.almostHim:
        return 3;
      case Difficulty.canonEvent:
        return 1;
    }
  }
}

/// Holds the selected config before launching a quiz
final quizConfigProvider =
    StateProvider<QuizConfig>((ref) => const QuizConfig());

// ── Quiz State ──

class QuizState {
  final bool isLoading;
  final List<Question> questions;
  final int currentIndex;
  final int score;
  final List<String> missedQuestionIds;
  final bool isFinished;
  final DateTime startTime;
  final QuizConfig config;
  final int livesRemaining;
  final bool isGameOver; // True when lives run out in Almost Him

  QuizState({
    this.isLoading = true,
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.missedQuestionIds = const [],
    this.isFinished = false,
    DateTime? startTime,
    this.config = const QuizConfig(),
    int? livesRemaining,
    this.isGameOver = false,
  })  : startTime = startTime ?? DateTime.now(),
        livesRemaining = livesRemaining ?? config.maxLives;

  QuizState copyWith({
    bool? isLoading,
    List<Question>? questions,
    int? currentIndex,
    int? score,
    List<String>? missedQuestionIds,
    bool? isFinished,
    DateTime? startTime,
    QuizConfig? config,
    int? livesRemaining,
    bool? isGameOver,
  }) {
    return QuizState(
      isLoading: isLoading ?? this.isLoading,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      missedQuestionIds: missedQuestionIds ?? this.missedQuestionIds,
      isFinished: isFinished ?? this.isFinished,
      startTime: startTime ?? this.startTime,
      config: config ?? this.config,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      isGameOver: isGameOver ?? this.isGameOver,
    );
  }
}

// ── Quiz Provider ──

class QuizProviderNotifier
    extends AutoDisposeFamilyAsyncNotifier<QuizState, String> {
  late String _subjectId;
  late String _categoryId;

  @override
  Future<QuizState> build(String arg) async {
    _subjectId = arg;
    final dbService = ref.read(databaseServiceProvider);
    final config = ref.read(quizConfigProvider);

    // Determine category ID from subject ID
    final subjectMaps = await dbService.db
        .query('subjects', where: 'id = ?', whereArgs: [_subjectId]);
    if (subjectMaps.isNotEmpty) {
      _categoryId = subjectMaps.first['category_id'] as String;
    } else {
      throw Exception('Subject not found');
    }

    // Load questions
    final questionMaps = await dbService.db
        .query('questions', where: 'subject_id = ?', whereArgs: [_subjectId]);
    final questions = questionMaps.map((m) => Question.fromMap(m)).toList();

    // Shuffle question order + randomize answer positions
    questions.shuffle();
    final shuffledQuestions = questions.map((q) => q.shuffled()).toList();

    // Apply question limit
    final limited = config.questionLimit != null
        ? shuffledQuestions.take(config.questionLimit!).toList()
        : shuffledQuestions;

    return QuizState(
      isLoading: false,
      questions: limited,
      startTime: DateTime.now(),
      config: config,
    );
  }

  void answerQuestion(int selectedIndex) async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isFinished ||
        currentState.isGameOver) {
      return;
    }

    final currentQuestion = currentState.questions[currentState.currentIndex];
    bool isCorrect = selectedIndex == currentQuestion.correctIndex;

    final newScore = currentState.score + (isCorrect ? 1 : 0);
    final List<String> newMissedIds = List.from(currentState.missedQuestionIds);
    int newLives = currentState.livesRemaining;

    if (!isCorrect) {
      newMissedIds.add(currentQuestion.id);

      // Handle lives for non-PlotArmor modes
      if (currentState.config.difficulty != Difficulty.plotArmor) {
        newLives = newLives - 1;
      }
    }

    // Check if game over (lives depleted in Almost Him or Canon Event mode)
    if (newLives == 0 &&
        currentState.config.difficulty != Difficulty.plotArmor) {
      ref.read(audioServiceProvider).playIncorrect();
      await _saveAttempt(currentState, newScore, newMissedIds);
      state = AsyncValue.data(currentState.copyWith(
        score: newScore,
        missedQuestionIds: newMissedIds,
        livesRemaining: 0,
        isGameOver: true,
        isFinished: true,
      ));
      return;
    }

    final isLastQuestion =
        currentState.currentIndex + 1 >= currentState.questions.length;

    if (!isLastQuestion) {
      if (!isCorrect) {
        ref.read(audioServiceProvider).playIncorrect();
      } else {
        ref.read(audioServiceProvider).playCorrect();
      }
    }

    if (isLastQuestion) {
      await _saveAttempt(currentState, newScore, newMissedIds);

      ref.read(audioServiceProvider).playLevelUp();

      if (newScore > 0) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          ref.read(audioServiceProvider).playMagicalStreak();
        });
      }

      state = AsyncValue.data(currentState.copyWith(
        score: newScore,
        missedQuestionIds: newMissedIds,
        livesRemaining: newLives,
        isFinished: true,
      ));
    } else {
      state = AsyncValue.data(currentState.copyWith(
        currentIndex: currentState.currentIndex + 1,
        score: newScore,
        missedQuestionIds: newMissedIds,
        livesRemaining: newLives,
      ));
    }
  }

  /// Called when the timer runs out on a timed question
  void timeOut() {
    final currentState = state.value;
    if (currentState == null || currentState.isFinished) return;
    // Treat timeout as wrong answer — pass an impossible index
    answerQuestion(-1);
  }

  /// End quiz early and save progress
  void endQuizEarly() async {
    final currentState = state.value;
    if (currentState == null || currentState.isFinished) return;

    await _saveAttempt(
        currentState, currentState.score, currentState.missedQuestionIds);

    state = AsyncValue.data(currentState.copyWith(
      isFinished: true,
    ));
  }

  Future<void> _saveAttempt(
      QuizState currentState, int score, List<String> missedIds) async {
    final timeTaken =
        DateTime.now().difference(currentState.startTime).inSeconds;

    final attempt = QuizAttempt(
      id: const Uuid().v4(),
      categoryId: _categoryId,
      date: DateTime.now(),
      score: score,
      totalQuestions: currentState.questions.length,
      timeTakenSeconds: timeTaken,
      missedQuestionIds: missedIds,
    );

    await ref
        .read(databaseServiceProvider)
        .db
        .insert('quiz_attempts', attempt.toMap());

    ref.invalidate(streakProvider);
    ref.invalidate(historyProvider);
  }

  void restartWithMistakes() {
    final currentState = state.value;
    if (currentState == null || !currentState.isFinished) return;

    final missedQuestions = currentState.questions
        .where((q) => currentState.missedQuestionIds.contains(q.id))
        .toList();

    state = AsyncValue.data(QuizState(
      isLoading: false,
      questions: missedQuestions,
      startTime: DateTime.now(),
      config: currentState.config,
    ));
  }
}

final quizProvider = AsyncNotifierProvider.autoDispose
    .family<QuizProviderNotifier, QuizState, String>(() {
  return QuizProviderNotifier();
});
