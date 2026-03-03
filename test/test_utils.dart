import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ergo/core/database/database_service.dart';
import 'package:ergo/core/audio/audio_service.dart';

// Mocks
class MockDatabaseService extends Mock implements DatabaseService {}

class MockDatabase extends Mock implements Database {}

class MockAudioService extends Mock implements AudioService {}

class TestUtils {
  static ProviderContainer createContainer({
    ProviderContainer? parent,
    List<Override> overrides = const [],
    List<ProviderObserver>? observers,
  }) {
    final container = ProviderContainer(
      parent: parent,
      overrides: overrides,
      observers: observers,
    );
    return container;
  }
}
