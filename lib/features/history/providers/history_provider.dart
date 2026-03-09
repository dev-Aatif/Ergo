import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/quiz_attempt.dart';

// ── Stats Models ──

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

  // Tier 1 — new stats
  final int bestStreakEver;
  final String? mostPlayedSubject;
  final Map<String, int> difficultyBreakdown;
  final double fastestQuizPace; // lowest time per question
  final double improvementTrend; // accuracy delta last 7 vs prior 7
  final double knowledgeVolatility; // score variance
  final Map<int, double> chronotypeAccuracy; // hour → accuracy
  final double avgReturnHours; // avg gap between sessions
  final double abandonmentRate; // early-quit ratio
  final int revengeSessions; // sessions within 60s of poor score

  // Tier 2 — from answer_log
  final double avgTimeCorrectMs;
  final double avgTimeIncorrectMs;
  final double fatigueIndex; // accuracy drop: first 5 vs last 5
  final double clutchAccuracy; // accuracy on final question
  final double tiltFactor; // P(wrong | 2+ consecutive wrong)

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
    this.bestStreakEver = 0,
    this.mostPlayedSubject,
    this.difficultyBreakdown = const {},
    this.fastestQuizPace = 0,
    this.improvementTrend = 0,
    this.knowledgeVolatility = 0,
    this.chronotypeAccuracy = const {},
    this.avgReturnHours = 0,
    this.abandonmentRate = 0,
    this.revengeSessions = 0,
    this.avgTimeCorrectMs = 0,
    this.avgTimeIncorrectMs = 0,
    this.fatigueIndex = 0,
    this.clutchAccuracy = 0,
    this.tiltFactor = 0,
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

  // ── Fetch raw attempts ──
  final attemptMaps = selectedCategory != null
      ? await db.query('quiz_attempts',
          where: 'category_id = ?',
          whereArgs: [selectedCategory],
          orderBy: 'date ASC')
      : await db.query('quiz_attempts', orderBy: 'date ASC');

  final attempts = attemptMaps.map((m) => QuizAttempt.fromMap(m)).toList();

  // Category name lookup
  final categoryMaps = await db.query('categories');
  final categoryNames = <String, String>{};
  for (var c in categoryMaps) {
    categoryNames[c['id'] as String] = c['name'] as String;
  }

  // Subject name lookup
  final subjectMaps = await db.query('subjects');
  final subjectNames = <String, String>{};
  for (var s in subjectMaps) {
    subjectNames[s['id'] as String] = s['name'] as String;
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

  // ── Tier 1: Derive from quiz_attempts ──

  int totalCorrect = 0;
  int totalQuestions = 0;
  int totalTimeSeconds = 0;
  double bestScore = 0.0;

  Map<DateTime, int> heatMap = {};
  List<double> movingAvgs = [];
  Map<String, List<int>> catCorrect = {};
  Map<String, List<int>> catTotal = {};
  Map<String, List<int>> catTime = {};

  const int mvWindow = 5;
  List<double> recentScoresForMv = [];

  // Per-category score lists for volatility
  Map<String, List<double>> catScoreRatios = {};

  // Chronotype: accuracy by hour
  Map<int, List<double>> hourAccuracies = {};

  // Difficulty breakdown
  // We don't have difficulty stored in quiz_attempts, so skip for now
  // TODO: add difficulty column to quiz_attempts in future

  // Best streak
  Set<DateTime> activeDays = {};

  // Session gaps
  List<Duration> sessionGaps = [];

  // Fastest pace
  double fastestPace = double.infinity;

  // Revenge sessions
  int revengeSessions = 0;

  // Abandonment (early quit = very low completion)
  int earlyQuits = 0;

  // Last 7 vs prior 7 days
  final now = DateTime.now();
  final last7 = now.subtract(const Duration(days: 7));
  final prior7 = now.subtract(const Duration(days: 14));
  double last7Correct = 0, last7Total = 0;
  double prior7Correct = 0, prior7Total = 0;

  for (int i = 0; i < attempts.length; i++) {
    final attempt = attempts[i];
    totalCorrect += attempt.score;
    totalQuestions += attempt.totalQuestions;
    totalTimeSeconds += attempt.timeTakenSeconds;

    final ratio = attempt.totalQuestions > 0
        ? (attempt.score / attempt.totalQuestions)
        : 0.0;
    if (ratio > bestScore) bestScore = ratio;

    // Fastest pace
    if (attempt.totalQuestions > 0) {
      final pace = attempt.timeTakenSeconds / attempt.totalQuestions;
      if (pace < fastestPace && pace > 0) fastestPace = pace;
    }

    // Moving average
    recentScoresForMv.add(ratio);
    if (recentScoresForMv.length > mvWindow) recentScoresForMv.removeAt(0);
    double sum = recentScoresForMv.fold(0, (p, c) => p + c);
    movingAvgs.add(sum / recentScoresForMv.length);

    // Heatmap
    final date =
        DateTime(attempt.date.year, attempt.date.month, attempt.date.day);
    heatMap[date] = (heatMap[date] ?? 0) + 1;
    activeDays.add(date);

    // Category breakdown
    catCorrect.putIfAbsent(attempt.categoryId, () => []).add(attempt.score);
    catTotal
        .putIfAbsent(attempt.categoryId, () => [])
        .add(attempt.totalQuestions);
    catTime
        .putIfAbsent(attempt.categoryId, () => [])
        .add(attempt.timeTakenSeconds);
    catScoreRatios.putIfAbsent(attempt.categoryId, () => []).add(ratio);

    // Chronotype
    final hour = attempt.date.hour;
    hourAccuracies.putIfAbsent(hour, () => []).add(ratio);

    // Session gap
    if (i > 0) {
      final gap = attempt.date.difference(attempts[i - 1].date);
      sessionGaps.add(gap);

      // Revenge: session within 3 minutes of a poor score (<50%)
      if (gap.inSeconds < 180) {
        final prevRatio = attempts[i - 1].totalQuestions > 0
            ? attempts[i - 1].score / attempts[i - 1].totalQuestions
            : 0.0;
        if (prevRatio < 0.5) revengeSessions++;
      }
    }

    // Improvement trend
    if (attempt.date.isAfter(last7)) {
      last7Correct += attempt.score;
      last7Total += attempt.totalQuestions;
    } else if (attempt.date.isAfter(prior7)) {
      prior7Correct += attempt.score;
      prior7Total += attempt.totalQuestions;
    }

    // Abandonment: tracked via answer_log below
  }

  // Best streak calculation
  int bestStreak = 0;
  if (activeDays.isNotEmpty) {
    final sorted = activeDays.toList()..sort();
    int currentStreak = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        currentStreak++;
      } else {
        if (currentStreak > bestStreak) bestStreak = currentStreak;
        currentStreak = 1;
      }
    }
    if (currentStreak > bestStreak) bestStreak = currentStreak;
  }

  // Most played subject — count by category
  String? mostPlayed;
  int maxCount = 0;
  for (var entry in catCorrect.entries) {
    if (entry.value.length > maxCount) {
      maxCount = entry.value.length;
      mostPlayed = categoryNames[entry.key] ?? entry.key;
    }
  }

  // Knowledge volatility — average variance across categories
  double totalVariance = 0;
  int varCount = 0;
  for (var ratios in catScoreRatios.values) {
    if (ratios.length > 1) {
      final mean = ratios.reduce((a, b) => a + b) / ratios.length;
      final variance =
          ratios.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
              ratios.length;
      totalVariance += variance;
      varCount++;
    }
  }

  // Chronotype map
  Map<int, double> chronotype = {};
  for (var entry in hourAccuracies.entries) {
    chronotype[entry.key] =
        entry.value.reduce((a, b) => a + b) / entry.value.length;
  }

  // Avg return hours
  double avgReturn = 0;
  if (sessionGaps.isNotEmpty) {
    avgReturn = sessionGaps.map((g) => g.inMinutes).reduce((a, b) => a + b) /
        sessionGaps.length /
        60.0;
  }

  // Improvement trend
  final last7Acc = last7Total > 0 ? last7Correct / last7Total : 0.0;
  final prior7Acc = prior7Total > 0 ? prior7Correct / prior7Total : 0.0;

  // Category breakdown
  Map<String, CategoryStats> breakdown = {};
  for (var catId in catCorrect.keys) {
    final correct = catCorrect[catId]!.fold<int>(0, (a, b) => a + b);
    final total = catTotal[catId]!.fold<int>(0, (a, b) => a + b);
    final time = catTime[catId]!.fold<int>(0, (a, b) => a + b);
    breakdown[catId] = CategoryStats(
      categoryName: categoryNames[catId] ?? catId,
      quizCount: catCorrect[catId]!.length,
      accuracy: total > 0 ? correct / total : 0.0,
      avgTime: total > 0 ? time.toDouble() / total : 0.0,
    );
  }

  // ── Tier 2: From answer_log ──

  double avgTimeCorrectMs = 0;
  double avgTimeIncorrectMs = 0;
  double fatigueIndex = 0;
  double clutchAccuracy = 0;
  double tiltFactor = 0;

  // Build category filter clause for Tier 2 queries
  // When a category is selected, filter answer_log via attempt IDs
  final attemptIds = attempts.map((a) => a.id).toList();
  final String categoryJoin;
  final List<Object?> categoryArgs;
  if (selectedCategory != null && attemptIds.isNotEmpty) {
    categoryJoin = 'INNER JOIN quiz_attempts qa ON a.attempt_id = qa.id WHERE qa.category_id = ?';
    categoryArgs = [selectedCategory];
  } else {
    categoryJoin = '';
    categoryArgs = [];
  }

  try {
    // Time-to-correct vs time-to-incorrect
    final correctTimeResult = selectedCategory != null
        ? await db.rawQuery(
            'SELECT AVG(a.time_ms) as avg_ms FROM answer_log a $categoryJoin AND a.is_correct = 1',
            categoryArgs)
        : await db.rawQuery(
            'SELECT AVG(time_ms) as avg_ms FROM answer_log WHERE is_correct = 1');
    final incorrectTimeResult = selectedCategory != null
        ? await db.rawQuery(
            'SELECT AVG(a.time_ms) as avg_ms FROM answer_log a $categoryJoin AND a.is_correct = 0',
            categoryArgs)
        : await db.rawQuery(
            'SELECT AVG(time_ms) as avg_ms FROM answer_log WHERE is_correct = 0');
    avgTimeCorrectMs =
        (correctTimeResult.first['avg_ms'] as num?)?.toDouble() ?? 0;
    avgTimeIncorrectMs =
        (incorrectTimeResult.first['avg_ms'] as num?)?.toDouble() ?? 0;

    // Fatigue index: accuracy on first 25% vs last 25% of questions per attempt
    final fatigueResult = selectedCategory != null
        ? await db.rawQuery('''
          SELECT a.attempt_id, a.question_index, a.is_correct, b.max_idx
          FROM answer_log a
          INNER JOIN (
            SELECT attempt_id, MAX(question_index) as max_idx
            FROM answer_log GROUP BY attempt_id
          ) b ON a.attempt_id = b.attempt_id
          $categoryJoin
        ''', categoryArgs)
        : await db.rawQuery('''
          SELECT a.attempt_id, a.question_index, a.is_correct, b.max_idx
          FROM answer_log a
          INNER JOIN (
            SELECT attempt_id, MAX(question_index) as max_idx
            FROM answer_log GROUP BY attempt_id
          ) b ON a.attempt_id = b.attempt_id
        ''');

    double earlyCorrect = 0, earlyTotal = 0;
    double lateCorrect = 0, lateTotal = 0;
    for (final row in fatigueResult) {
      final idx = (row['question_index'] as int);
      final maxIdx = (row['max_idx'] as int);
      final isCorrect = (row['is_correct'] as int) == 1;
      // First 25% of questions
      if (idx <= maxIdx * 0.25) {
        earlyTotal++;
        if (isCorrect) earlyCorrect++;
      }
      // Last 25% of questions
      if (idx >= maxIdx * 0.75) {
        lateTotal++;
        if (isCorrect) lateCorrect++;
      }
    }
    final earlyAcc = earlyTotal > 0 ? earlyCorrect / earlyTotal : 0.0;
    final lateAcc = lateTotal > 0 ? lateCorrect / lateTotal : 0.0;
    fatigueIndex = earlyAcc - lateAcc; // positive = degradation

    // Clutch: accuracy on the max question_index per attempt
    final clutchResult = selectedCategory != null
        ? await db.rawQuery('''
          SELECT AVG(CAST(a.is_correct AS REAL)) as acc
          FROM answer_log a
          INNER JOIN (
            SELECT attempt_id, MAX(question_index) as max_idx
            FROM answer_log GROUP BY attempt_id
          ) b ON a.attempt_id = b.attempt_id AND a.question_index = b.max_idx
          $categoryJoin
        ''', categoryArgs)
        : await db.rawQuery('''
          SELECT AVG(CAST(a.is_correct AS REAL)) as acc
          FROM answer_log a
          INNER JOIN (
            SELECT attempt_id, MAX(question_index) as max_idx
            FROM answer_log GROUP BY attempt_id
          ) b ON a.attempt_id = b.attempt_id AND a.question_index = b.max_idx
        ''');
    clutchAccuracy = (clutchResult.first['acc'] as num?)?.toDouble() ?? 0;

    // Tilt factor: P(wrong after 2+ consecutive wrong)
    final allAnswers = selectedCategory != null
        ? await db.rawQuery(
            'SELECT a.attempt_id, a.question_index, a.is_correct FROM answer_log a $categoryJoin ORDER BY a.attempt_id, a.question_index',
            categoryArgs)
        : await db.query('answer_log',
            columns: ['attempt_id', 'question_index', 'is_correct'],
            orderBy: 'attempt_id, question_index');

    int tiltOpportunities = 0;
    int tiltWrong = 0;
    String? prevAttempt;
    int consecutiveWrong = 0;

    for (final row in allAnswers) {
      final attemptId = row['attempt_id'] as String;
      final isCorrect = (row['is_correct'] as int) == 1;

      if (attemptId != prevAttempt) {
        consecutiveWrong = 0;
        prevAttempt = attemptId;
      }

      if (consecutiveWrong >= 2) {
        tiltOpportunities++;
        if (!isCorrect) tiltWrong++;
      }

      if (!isCorrect) {
        consecutiveWrong++;
      } else {
        consecutiveWrong = 0;
      }
    }
    tiltFactor = tiltOpportunities > 0 ? tiltWrong / tiltOpportunities : 0;

    // Abandonment rate: compare answer_log count per attempt vs totalQuestions
    final answerCountResult = selectedCategory != null
        ? await db.rawQuery(
            'SELECT a.attempt_id, COUNT(*) as answered FROM answer_log a $categoryJoin GROUP BY a.attempt_id',
            categoryArgs)
        : await db.rawQuery(
            'SELECT attempt_id, COUNT(*) as answered FROM answer_log GROUP BY attempt_id');
    final answerCounts = <String, int>{};
    for (final row in answerCountResult) {
      answerCounts[row['attempt_id'] as String] = row['answered'] as int;
    }
    for (final attempt in attempts) {
      final answered = answerCounts[attempt.id] ?? 0;
      // If user answered less than half the questions, count as early quit
      if (attempt.totalQuestions > 0 &&
          answered < attempt.totalQuestions * 0.5) {
        earlyQuits++;
      }
    }
  } catch (_) {
    // answer_log table might not have data yet
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
    bestStreakEver: bestStreak,
    mostPlayedSubject: mostPlayed,
    difficultyBreakdown: {}, // TODO: needs difficulty column in quiz_attempts
    fastestQuizPace: fastestPace == double.infinity ? 0 : fastestPace,
    improvementTrend: last7Acc - prior7Acc,
    knowledgeVolatility: varCount > 0 ? totalVariance / varCount : 0,
    chronotypeAccuracy: chronotype,
    avgReturnHours: avgReturn,
    abandonmentRate: attempts.isNotEmpty ? earlyQuits / attempts.length : 0,
    revengeSessions: revengeSessions,
    avgTimeCorrectMs: avgTimeCorrectMs,
    avgTimeIncorrectMs: avgTimeIncorrectMs,
    fatigueIndex: fatigueIndex,
    clutchAccuracy: clutchAccuracy,
    tiltFactor: tiltFactor,
  );
});
