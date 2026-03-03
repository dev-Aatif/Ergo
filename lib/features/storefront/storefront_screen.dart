import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/storefront_provider.dart';
import '../../core/audio/audio_service.dart';
import 'models/catalog_item.dart';

class StorefrontScreen extends ConsumerWidget {
  const StorefrontScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storefrontProvider);
    final notifier = ref.read(storefrontProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Store', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.fetchCatalog(),
            tooltip: 'Refresh catalog',
          ),
        ],
      ),
      body: _buildBody(context, ref, state, notifier, theme),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, StorefrontState state,
      StorefrontNotifier notifier, ThemeData theme) {
    // Error banner at the top if there's an error but we still have items
    Widget? errorBanner;
    if (state.error != null) {
      errorBanner = Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded,
                color: theme.colorScheme.onErrorContainer, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.error!,
                style: TextStyle(
                    color: theme.colorScheme.onErrorContainer, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => notifier.fetchCatalog(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.items.isEmpty && state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text("Can't reach the store",
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(state.error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => notifier.fetchCatalog(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined,
                size: 64,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Store is empty', style: theme.textTheme.titleLarge),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (errorBanner != null) errorBanner,
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              final isDownloaded = state.downloadedItems.contains(item.id);
              final progress = state.downloadProgress[item.id];
              final isDownloading = progress != null;

              return _StoreCard(
                item: item,
                isDownloaded: isDownloaded,
                isDownloading: isDownloading,
                progress: progress ?? 0,
                isLoading: state.isLoading,
                onDownload: () {
                  ref.read(audioServiceProvider).playClick();
                  notifier.downloadAndInstall(item);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  final CatalogItem item;
  final bool isDownloaded;
  final bool isDownloading;
  final double progress;
  final bool isLoading;
  final VoidCallback onDownload;

  const _StoreCard({
    required this.item,
    required this.isDownloaded,
    required this.isDownloading,
    required this.progress,
    required this.isLoading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor =
        Color(int.parse(item.colorHex.replaceFirst('#', '0xFF')));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDownloaded
              ? accentColor.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Category color accent icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconForCategory(item.categoryName),
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Pack info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subjectName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.quiz_outlined,
                        label: '${item.questionCount} Q',
                        color: accentColor,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: item.categoryName,
                        color: accentColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Action button
            _buildAction(context, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, Color accentColor) {
    final theme = Theme.of(context);

    if (isDownloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            SizedBox(width: 4),
            Text('Installed',
                style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ],
        ),
      );
    }

    if (isDownloading) {
      return SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              color: accentColor,
              backgroundColor: accentColor.withValues(alpha: 0.15),
            ),
            Text('${(progress * 100).toInt()}',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
          ],
        ),
      );
    }

    return FilledButton.tonal(
      onPressed: isLoading ? null : onDownload,
      style: FilledButton.styleFrom(
        backgroundColor: accentColor.withValues(alpha: 0.12),
        foregroundColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_rounded, size: 16),
          SizedBox(width: 4),
          Text('Get',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'history':
        return Icons.auto_stories_rounded;
      case 'anime':
        return Icons.movie_filter_rounded;
      case 'movies':
        return Icons.theaters_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'sports':
        return Icons.sports_cricket_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
