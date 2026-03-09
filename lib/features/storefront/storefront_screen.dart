import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'providers/storefront_provider.dart';
import '../../core/audio/audio_service.dart';
import '../../core/utils.dart';
import 'models/catalog_item.dart';

class StorefrontScreen extends ConsumerStatefulWidget {
  const StorefrontScreen({super.key});

  @override
  ConsumerState<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends ConsumerState<StorefrontScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
    // Error banner
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

    // Filter items by search
    final filteredItems = _searchQuery.isEmpty
        ? state.items
        : state.items
            .where((item) =>
                item.subjectName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                item.categoryName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
            .toList();

    // Group by category
    final Map<String, List<CatalogItem>> grouped = {};
    for (final item in filteredItems) {
      grouped.putIfAbsent(item.categoryName, () => []).add(item);
    }
    final categoryNames = grouped.keys.toList()..sort();

    return Column(
      children: [
        if (errorBanner != null) errorBanner,

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SearchBar(
            hintText: 'Search subjects...',
            leading: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.search_rounded, size: 20),
            ),
            trailing: _searchQuery.isNotEmpty
                ? [
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  ]
                : null,
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(theme
                .colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 8)),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),

        // Grouped items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            itemCount: categoryNames.length + 1, // +1 for contribute banner
            itemBuilder: (context, index) {
              // Contribute banner at the bottom
              if (index == categoryNames.length) {
                return _ContributeBanner();
              }

              final categoryName = categoryNames[index];
              final items = grouped[categoryName]!;

              return _CategorySection(
                categoryName: categoryName,
                items: items,
                state: state,
                onDownload: (item) {
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

// ── Category Section with ExpansionTile ──

class _CategorySection extends StatelessWidget {
  final String categoryName;
  final List<CatalogItem> items;
  final StorefrontState state;
  final void Function(CatalogItem) onDownload;

  const _CategorySection({
    required this.categoryName,
    required this.items,
    required this.state,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use the first item's color as the section accent
    final accentColor = safeParseColor(items.first.colorHex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(getIconForName(items.first.iconUrl),
                color: accentColor, size: 20),
          ),
          title: Text(
            categoryName,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${items.length} pack${items.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: items
              .map((item) => _StoreItemTile(
                    item: item,
                    isDownloaded: state.downloadedItems.contains(item.id),
                    isDownloading: state.downloadProgress.containsKey(item.id),
                    progress: state.downloadProgress[item.id] ?? 0,
                    isLoading: state.isLoading,
                    onDownload: () => onDownload(item),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ── Store Item Tile ──

class _StoreItemTile extends StatelessWidget {
  final CatalogItem item;
  final bool isDownloaded;
  final bool isDownloading;
  final double progress;
  final bool isLoading;
  final VoidCallback onDownload;

  const _StoreItemTile({
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
    final accentColor = safeParseColor(item.colorHex);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDownloaded
                ? accentColor.withValues(alpha: 0.2)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subjectName,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
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
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildAction(context, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, Color accentColor) {
    if (isDownloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 14),
            SizedBox(width: 4),
            Text('Installed',
                style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 11)),
          ],
        ),
      );
    }

    if (isDownloading) {
      return SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.5,
              color: accentColor,
              backgroundColor: accentColor.withValues(alpha: 0.15),
            ),
            Text('${(progress * 100).toInt()}',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      );
    }

    return FilledButton.tonal(
      onPressed: isLoading ? null : onDownload,
      style: FilledButton.styleFrom(
        backgroundColor: accentColor.withValues(alpha: 0.12),
        foregroundColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_rounded, size: 14),
          SizedBox(width: 4),
          Text('Get',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Info Chip ──

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

// ── Contribute Banner ──

class _ContributeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.colorScheme.tertiary.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.volunteer_activism_rounded,
                size: 32,
                color: theme.colorScheme.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(
              'Want more packs?',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Contribute questions or create your own quiz pack for the community!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse('https://github.com/dev-Aatif/ergo-db');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Contribute on GitHub'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
