import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';

final streakProvider = FutureProvider<int>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  final db = dbService.db;

  // Retrieve distinct dates of quiz attempts ordered by date descending.
  // We use date(date / 1000, 'unixepoch', 'localtime') to group by local days.
  final results = await db.rawQuery('''
    SELECT DISTINCT date(date / 1000, 'unixepoch', 'localtime') as attempt_date 
    FROM quiz_attempts 
    ORDER BY attempt_date DESC
  ''');

  if (results.isEmpty) return 0;

  final now = DateTime.now();
  final todayStr =
      "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  final yesterday = now.subtract(const Duration(days: 1));
  final yesterdayStr =
      "${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

  int streak = 0;
  DateTime expectedDate = now;

  // Check if first date is today or yesterday to start the streak
  final firstDateStr = results.first['attempt_date'] as String;
  if (firstDateStr == todayStr) {
    streak = 1;
    expectedDate = yesterday;
  } else if (firstDateStr == yesterdayStr) {
    streak = 1;
    expectedDate = yesterday.subtract(const Duration(days: 1));
  } else {
    // If last attempt was before yesterday, streak is broken/zero
    return 0;
  }

  // Iterate from the second record backwards to count consecutive days
  for (int i = 1; i < results.length; i++) {
    final expectedStr =
        "${expectedDate.year.toString().padLeft(4, '0')}-${expectedDate.month.toString().padLeft(2, '0')}-${expectedDate.day.toString().padLeft(2, '0')}";
    final currentStr = results[i]['attempt_date'] as String;

    if (currentStr == expectedStr) {
      streak++;
      expectedDate = expectedDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  return streak;
});
