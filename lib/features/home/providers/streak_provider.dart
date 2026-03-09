import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';

class StreakData {
  final int currentStreak;
  final int bestStreak;
  final List<bool> last14Days; // true = played, most recent first

  const StreakData({
    required this.currentStreak,
    required this.bestStreak,
    required this.last14Days,
  });
}

final streakProvider = FutureProvider<StreakData>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  final db = dbService.db;

  // Get distinct dates
  final results = await db.rawQuery('''
    SELECT DISTINCT date(date / 1000, 'unixepoch', 'localtime') as attempt_date 
    FROM quiz_attempts 
    ORDER BY attempt_date DESC
  ''');

  if (results.isEmpty) {
    return StreakData(
      currentStreak: 0,
      bestStreak: 0,
      last14Days: List.filled(14, false),
    );
  }

  final activeDates = results.map((r) => r['attempt_date'] as String).toSet();

  // Current streak
  final now = DateTime.now();
  final todayStr = _dateStr(now);
  final yesterdayStr = _dateStr(now.subtract(const Duration(days: 1)));

  int currentStreak = 0;
  DateTime expectedDate = now;

  if (activeDates.contains(todayStr)) {
    currentStreak = 1;
    expectedDate = now.subtract(const Duration(days: 1));
  } else if (activeDates.contains(yesterdayStr)) {
    currentStreak = 1;
    expectedDate = now.subtract(const Duration(days: 2));
  } else {
    // Streak broken
    currentStreak = 0;
    expectedDate = now; // won't matter
  }

  if (currentStreak > 0) {
    for (int i = 1; i < results.length; i++) {
      if (activeDates.contains(_dateStr(expectedDate))) {
        currentStreak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
  }

  // Best streak — scan all dates
  final sortedDates = activeDates.toList()..sort();
  int bestStreak = sortedDates.isEmpty ? 0 : 1;
  int runStreak = 1;
  for (int i = 1; i < sortedDates.length; i++) {
    final prev = DateTime.parse(sortedDates[i - 1]);
    final curr = DateTime.parse(sortedDates[i]);
    if (curr.difference(prev).inDays == 1) {
      runStreak++;
      if (runStreak > bestStreak) bestStreak = runStreak;
    } else {
      runStreak = 1;
    }
  }

  // Last 14 days
  final last14 = List.generate(14, (i) {
    final day = now.subtract(Duration(days: i));
    return activeDates.contains(_dateStr(day));
  });

  return StreakData(
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    last14Days: last14,
  );
});

String _dateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
