import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/question.dart';
import '../../../core/models/quiz_attempt.dart';

class QuizState {
  final bool isLoading;
  final List<Question> questions;
  final int currentIndex;
  final int score;
  final List<String> missedQuestionIds;
  final bool isFinished;
  final DateTime startTime;

  QuizState({
    this.isLoading = true,
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.missedQuestionIds = const [],
    this.isFinished = false,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  QuizState copyWith({
    bool? isLoading,
    List<Question>? questions,
    int? currentIndex,
    int? score,
    List<String>? missedQuestionIds,
    bool? isFinished,
    DateTime? startTime,
  }) {
    return QuizState(
      isLoading: isLoading ?? this.isLoading,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      missedQuestionIds: missedQuestionIds ?? this.missedQuestionIds,
      isFinished: isFinished ?? this.isFinished,
      startTime: startTime ?? this.startTime,
    );
  }
}

class QuizProviderNotifier
    extends AutoDisposeFamilyAsyncNotifier<QuizState, String> {
  late String _subjectId;
  late String _categoryId; // For saving attempt

  @override
  Future<QuizState> build(String arg) async {
    _subjectId = arg;
    final dbService = ref.read(databaseServiceProvider);

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

    // Shuffle options could be done here, but MVP logic assumes straight fetch
    return QuizState(
        isLoading: false, questions: questions, startTime: DateTime.now());
  }

  void answerQuestion(int selectedIndex) async {
    final currentState = state.value;
    if (currentState == null || currentState.isFinished) return;

    final currentQuestion = currentState.questions[currentState.currentIndex];
    bool isCorrect = selectedIndex == currentQuestion.correctIndex;

    final newScore = currentState.score + (isCorrect ? 1 : 0);
    final List<String> newMissedIds = List.from(currentState.missedQuestionIds);
    if (!isCorrect) {
      newMissedIds.add(currentQuestion.id);
    }

    if (currentState.currentIndex + 1 >= currentState.questions.length) {
      // Finish quiz
      final timeTaken =
          DateTime.now().difference(currentState.startTime).inSeconds;

      // Save Attempt
      final attempt = QuizAttempt(
        id: const Uuid().v4(),
        categoryId: _categoryId,
        date: DateTime.now(),
        score: newScore,
        totalQuestions: currentState.questions.length,
        timeTakenSeconds: timeTaken,
        missedQuestionIds: newMissedIds,
      );

      await ref
          .read(databaseServiceProvider)
          .db
          .insert('quiz_attempts', attempt.toMap());

      // Invalidate streak provider to refresh home screen
      // ref.invalidate(streakProvider); // Can be added via another provider dependency if needed

      state = AsyncValue.data(currentState.copyWith(
        score: newScore,
        missedQuestionIds: newMissedIds,
        isFinished: true,
      ));
    } else {
      // Next question
      state = AsyncValue.data(currentState.copyWith(
        currentIndex: currentState.currentIndex + 1,
        score: newScore,
        missedQuestionIds: newMissedIds,
      ));
    }
  }

  // Method for review mistakes mode
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
    ));
  }
}

final quizProvider = AsyncNotifierProvider.autoDispose
    .family<QuizProviderNotifier, QuizState, String>(() {
  return QuizProviderNotifier();
});
