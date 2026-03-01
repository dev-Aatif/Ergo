import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/subject.dart';

final subjectsProvider =
    FutureProvider.family<List<Subject>, String>((ref, categoryId) async {
  final dbService = ref.watch(databaseServiceProvider);
  final db = dbService.db;

  final List<Map<String, dynamic>> maps = await db.query(
    'subjects',
    where: 'category_id = ?',
    whereArgs: [categoryId],
  );

  return List.generate(maps.length, (i) {
    return Subject.fromMap(maps[i]);
  });
});
