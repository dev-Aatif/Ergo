import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/quiz_attempt.dart';

class HistoryStats {
  final List<QuizAttempt> recentAttempts;
  final Map<DateTime, int> heatMapData;
  final double globalAccuracy;
  final int totalQuizzesTaken;
  final int totalQuestionsAnswered;
  final double averageTimePerQuestion;
  final double bestScorePercentage;
  final List<double> movingAverageScoring;
  final Map<String, CategoryStats> categoryBreakdown;

  HistoryStats({
    required this.recentAttempts,
    required this.heatMapData,
    required this.globalAccuracy,
    required this.totalQuizzesTaken,
    required this.totalQuestionsAnswered,
    required this.averageTimePerQuestion,
    required this.bestScorePercentage,
    required this.movingAverageScoring,
    required this.categoryBreakdown,
  });
}

class CategoryStats {
  final String categoryName;
  final int quizCount;
  final double accuracy;
  final double avgTime;

  CategoryStats({
    required this.categoryName,
    required this.quizCount,
    required this.accuracy,
    required this.avgTime,
  });
}

/// Selected category filter for analytics
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final historyProvider = FutureProvider<HistoryStats>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  final db = dbService.db;
  final selectedCategory = ref.watch(selectedCategoryProvider);

  // Fetch all raw attempts
  final attemptMaps = selectedCategory != null
      ? await db.query('quiz_attempts',
          where: 'category_id = ?',
          whereArgs: [selectedCategory],
          orderBy: 'date ASC')
      : await db.query('quiz_attempts', orderBy: 'date ASC');

  final attempts = attemptMaps.map((m) => QuizAttempt.fromMap(m)).toList();

  // Fetch category names for breakdown
  final categoryMaps = await db.query('categories');
  final categoryNames = <String, String>{};
  for (var c in categoryMaps) {
    categoryNames[c['id'] as String] = c['name'] as String;
  }

  if (attempts.isEmpty) {
    return HistoryStats(
      recentAttempts: [],
      heatMapData: {},
      globalAccuracy: 0.0,
      totalQuizzesTaken: 0,
      totalQuestionsAnswered: 0,
      averageTimePerQuestion: 0.0,
      bestScorePercentage: 0.0,
      movingAverageScoring: [],
      categoryBreakdown: {},
    );
  }

  int totalCorrect = 0;
  int totalQuestions = 0;
  int totalTimeSeconds = 0;
  double bestScore = 0.0;

  Map<DateTime, int> heatMap = {};
  List<double> movingAvgs = [];

  // Per-category accumulators
  Map<String, List<int>> catCorrect = {};
  Map<String, List<int>> catTotal = {};
  Map<String, List<int>> catTime = {};

  const int mvWindow = 5;
  List<double> recentScoresForMv = [];

  for (var attempt in attempts) {
    totalCorrect = totalCorrect + attempt.score;
    totalQuestions = totalQuestions + attempt.totalQuestions;
    totalTimeSeconds = totalTimeSeconds + attempt.timeTakenSeconds;

    final ratio = attempt.totalQuestions > 0
        ? (attempt.score / attempt.totalQuestions)
        : 0.0;
    if (ratio > bestScore) bestScore = ratio;

    recentScoresForMv.add(ratio);
    if (recentScoresForMv.length > mvWindow) {
      recentScoresForMv.removeAt(0);
    }

    double sum = recentScoresForMv.fold(0, (p, c) => p + c);
    movingAvgs.add(sum / recentScoresForMv.length);

    final date =
        DateTime(attempt.date.year, attempt.date.month, attempt.date.day);
    heatMap[date] = (heatMap[date] ?? 0) + 1;

    // Category breakdown
    catCorrect.putIfAbsent(attempt.categoryId, () => []).add(attempt.score);
    catTotal
        .putIfAbsent(attempt.categoryId, () => [])
        .add(attempt.totalQuestions);
    catTime
        .putIfAbsent(attempt.categoryId, () => [])
        .add(attempt.timeTakenSeconds);
  }

  // Build category breakdown
  Map<String, CategoryStats> breakdown = {};
  for (var catId in catCorrect.keys) {
    final correct = catCorrect[catId]!.fold<int>(0, (a, b) => a + b);
    final total = catTotal[catId]!.fold<int>(0, (a, b) => a + b);
    final time = catTime[catId]!.fold<int>(0, (a, b) => a + b);

    breakdown[catId] = CategoryStats(
      categoryName: categoryNames[catId] ?? catId,
      quizCount: catCorrect[catId]!.length,
      accuracy: total > 0 ? correct / total : 0.0,
      avgTime: total > 0 ? time / total : 0.0,
    );
  }

  final recents = attempts.reversed.take(20).toList().reversed.toList();
  final recentMv = movingAvgs.reversed.take(20).toList().reversed.toList();

  return HistoryStats(
    recentAttempts: recents,
    heatMapData: heatMap,
    globalAccuracy: totalQuestions > 0 ? (totalCorrect / totalQuestions) : 0.0,
    totalQuizzesTaken: attempts.length,
    totalQuestionsAnswered: totalQuestions,
    averageTimePerQuestion:
        totalQuestions > 0 ? (totalTimeSeconds / totalQuestions) : 0.0,
    bestScorePercentage: bestScore,
    movingAverageScoring: recentMv,
    categoryBreakdown: breakdown,
  );
});
