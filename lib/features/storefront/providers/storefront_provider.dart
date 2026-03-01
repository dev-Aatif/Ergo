import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/database_service.dart';
import '../models/catalog_item.dart';

final storefrontProvider =
    StateNotifierProvider<StorefrontNotifier, StorefrontState>((ref) {
  return StorefrontNotifier(ref);
});

class StorefrontState {
  final bool isLoading;
  final List<CatalogItem> items;
  final String? error;
  final Map<String, double>
      downloadProgress; // key: itemId, value: progress 0.0 to 1.0
  final Set<String> downloadedItems;

  StorefrontState({
    this.isLoading = false,
    this.items = const [],
    this.error,
    this.downloadProgress = const {},
    this.downloadedItems = const {},
  });

  StorefrontState copyWith({
    bool? isLoading,
    List<CatalogItem>? items,
    String? error,
    Map<String, double>? downloadProgress,
    Set<String>? downloadedItems,
  }) {
    return StorefrontState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: error,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedItems: downloadedItems ?? this.downloadedItems,
    );
  }
}

class StorefrontNotifier extends StateNotifier<StorefrontState> {
  final Ref ref;
  // Use a mocked URL or raw GitHub for MVP.
  // For safety, we will mock the fetch logic if URL is not defined, or we can use a dummy JSON.
  static const String catalogUrl =
      'https://raw.githubusercontent.com/dev-Aatif/ergo-db/main/catalog.json';

  StorefrontNotifier(this.ref) : super(StorefrontState()) {
    _initDownloadedItems();
  }

  Future<void> _initDownloadedItems() async {
    final dbService = ref.read(databaseServiceProvider);
    final subjectMaps = await dbService.db.query('subjects');
    final downloadedIds = subjectMaps.map((m) => m['id'] as String).toSet();
    state = state.copyWith(downloadedItems: downloadedIds);
    fetchCatalog();
  }

  Future<void> fetchCatalog() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await http.get(Uri.parse(catalogUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final items = data.map((json) => CatalogItem.fromJson(json)).toList();
        state = state.copyWith(isLoading: false, items: items);
      } else {
        throw Exception(
            'Failed to load catalog. Status code: ${response.statusCode}');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> downloadAndInstall(CatalogItem item) async {
    if (state.downloadProgress.containsKey(item.id) ||
        state.downloadedItems.contains(item.id)) {
      return;
    }

    final updatedProgress = Map<String, double>.from(state.downloadProgress);
    updatedProgress[item.id] = 0.1;
    state = state.copyWith(downloadProgress: updatedProgress);

    try {
      // Simulate fake fast download progress for UI (since files are tiny, we won't stream bytes for now)
      final prog1 = Map<String, double>.from(state.downloadProgress);
      prog1[item.id] = 0.3;
      state = state.copyWith(downloadProgress: prog1);

      // 1. Download file
      final response = await http.get(Uri.parse(item.downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download: ${response.statusCode}');
      }

      final prog2 = Map<String, double>.from(state.downloadProgress);
      prog2[item.id] = 0.8;
      state = state.copyWith(downloadProgress: prog2);

      // 2. Save it to temp file
      final dir = await getApplicationDocumentsDirectory();
      final tempFile = File('${dir.path}/temp_${item.id}.db');
      await tempFile.writeAsBytes(response.bodyBytes);

      // 3. Merge DB
      final dbService = ref.read(databaseServiceProvider);
      await dbService.mergeDlcDatabase(tempFile.path);

      // 4. Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // Finish
      final prog = Map<String, double>.from(state.downloadProgress);
      prog.remove(item.id);
      final downloaded = Set<String>.from(state.downloadedItems);
      downloaded.add(item.id);

      state =
          state.copyWith(downloadProgress: prog, downloadedItems: downloaded);
    } catch (e) {
      final prog = Map<String, double>.from(state.downloadProgress);
      prog.remove(item.id);
      state =
          state.copyWith(error: 'Download failed: $e', downloadProgress: prog);
    }
  }
}
