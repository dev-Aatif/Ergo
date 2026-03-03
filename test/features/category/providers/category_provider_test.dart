import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ergo/features/category/providers/category_provider.dart';
import 'package:ergo/core/database/database_service.dart';

import '../../../test_utils.dart';

void main() {
  late Database db;
  late MockDatabaseService mockDbService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('''
                CREATE TABLE categories (
                  id TEXT PRIMARY KEY,
                  name TEXT NOT NULL,
                  accent_color TEXT NOT NULL,
                  icon_name TEXT NOT NULL
                );
              ''');
              await db.execute('''
                CREATE TABLE subjects (
                  id TEXT PRIMARY KEY,
                  category_id TEXT NOT NULL,
                  name TEXT NOT NULL,
                  description TEXT NOT NULL DEFAULT ''
                );
              ''');
              // Seed test data
              await db.insert('categories', {
                'id': 'cat_1',
                'name': 'History',
                'accent_color': '#FF9800',
                'icon_name': 'history',
              });
              await db.insert('categories', {
                'id': 'cat_2',
                'name': 'Science',
                'accent_color': '#4CAF50',
                'icon_name': 'science',
              });
              await db.insert('subjects', {
                'id': 'sub_1',
                'category_id': 'cat_1',
                'name': 'World History',
                'description': 'A broad overview of world history.',
              });
              await db.insert('subjects', {
                'id': 'sub_2',
                'category_id': 'cat_1',
                'name': 'Ancient Egypt',
                'description': 'Pharaohs, pyramids, and the Nile.',
              });
              await db.insert('subjects', {
                'id': 'sub_3',
                'category_id': 'cat_2',
                'name': 'Physics',
                'description': 'Gravity, light, and motion.',
              });
            }));

    mockDbService = MockDatabaseService();
    when(() => mockDbService.db).thenReturn(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Returns subjects for a given category', () async {
    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final subjects = await container.read(subjectsProvider('cat_1').future);

    expect(subjects.length, 2);
    expect(subjects[0].name, 'World History');
    expect(subjects[0].description, 'A broad overview of world history.');
    expect(subjects[1].name, 'Ancient Egypt');
  });

  test('Returns empty list for unknown category', () async {
    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final subjects =
        await container.read(subjectsProvider('nonexistent').future);

    expect(subjects, isEmpty);
  });

  test('Returns only subjects belonging to the requested category', () async {
    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final scienceSubjects =
        await container.read(subjectsProvider('cat_2').future);

    expect(scienceSubjects.length, 1);
    expect(scienceSubjects[0].name, 'Physics');
    expect(scienceSubjects[0].categoryId, 'cat_2');
  });

  test('Subject includes description field', () async {
    final container = TestUtils.createContainer(
      overrides: [databaseServiceProvider.overrideWithValue(mockDbService)],
    );

    final subjects = await container.read(subjectsProvider('cat_2').future);

    expect(subjects[0].description, 'Gravity, light, and motion.');
  });
}
