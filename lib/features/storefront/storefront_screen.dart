import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/storefront_provider.dart';

class StorefrontScreen extends ConsumerWidget {
  const StorefrontScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storefrontProvider);
    final notifier = ref.read(storefrontProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storefront',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.fetchCatalog(),
          )
        ],
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(BuildContext context, StorefrontState state,
      StorefrontNotifier notifier) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.fetchCatalog(),
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return const Center(child: Text('No subjects available for download.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        final isDownloaded = state.downloadedItems.contains(item.id);
        final progress = state.downloadProgress[item.id];
        final isDownloading = progress != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.subjectName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(item.description,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('${item.questionCount} Questions',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    if (isDownloaded)
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 32)
                    else if (isDownloading)
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(value: progress),
                            Text('${(progress * 100).toInt()}%',
                                style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => notifier.downloadAndInstall(item),
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                        ),
                        child: const Icon(Icons.download),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
