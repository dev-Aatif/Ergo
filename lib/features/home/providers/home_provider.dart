import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/category.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  final db = dbService.db;

  final List<Map<String, dynamic>> maps = await db.query('categories');

  return List.generate(maps.length, (i) {
    return Category.fromMap(maps[i]);
  });
});
