import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';

class AnalyticsData {
  final int totalQuizzes;
  final double averageAccuracy;
  final int totalTimeSpentSeconds;

  const AnalyticsData({
    required this.totalQuizzes,
    required this.averageAccuracy,
    required this.totalTimeSpentSeconds,
  });
}

final analyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  final db = dbService.db;

  final results = await db.query('quiz_attempts');

  if (results.isEmpty) {
    return const AnalyticsData(
      totalQuizzes: 0,
      averageAccuracy: 0.0,
      totalTimeSpentSeconds: 0,
    );
  }

  int totalScore = 0;
  int totalQuestions = 0;
  int timeSpent = 0;

  for (final row in results) {
    totalScore += row['score'] as int;
    totalQuestions += row['total_questions'] as int;
    timeSpent += row['time_taken'] as int;
  }

  final accuracy =
      totalQuestions > 0 ? (totalScore / totalQuestions) * 100 : 0.0;

  return AnalyticsData(
    totalQuizzes: results.length,
    averageAccuracy: accuracy,
    totalTimeSpentSeconds: timeSpent,
  );
});
