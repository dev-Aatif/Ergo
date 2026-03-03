import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── App Hero ──
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                        theme.colorScheme.tertiary.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/app-logo.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ergo',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A scalable, offline-first mobile learning app.\nLearn anything, anywhere — no internet required.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Developer ──
          _SectionHeader(title: 'Developer', icon: Icons.code_rounded),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              _CardRow(
                icon: Icons.person_rounded,
                label: 'Built by',
                value: 'Aatif',
              ),
              const Divider(height: 1),
              _CardRow(
                icon: Icons.laptop_mac_rounded,
                label: 'GitHub',
                value: '@dev-Aatif',
                onTap: () => _openUrl('https://github.com/dev-Aatif'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Links ──
          _SectionHeader(title: 'Links', icon: Icons.link_rounded),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              _LinkTile(
                icon: Icons.source_rounded,
                title: 'Source Code',
                subtitle: 'github.com/dev-Aatif/ergo',
                onTap: () => _openUrl('https://github.com/dev-Aatif/ergo'),
              ),
              const Divider(height: 1),
              _LinkTile(
                icon: Icons.bug_report_rounded,
                title: 'Report an Issue',
                subtitle: 'Open a GitHub issue',
                onTap: () =>
                    _openUrl('https://github.com/dev-Aatif/ergo/issues/new'),
              ),
              const Divider(height: 1),
              _LinkTile(
                icon: Icons.storage_rounded,
                title: 'Quiz Database',
                subtitle: 'Contribute questions & DLC packs',
                onTap: () => _openUrl('https://github.com/dev-Aatif/ergo-db'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Privacy ──
          _SectionHeader(title: 'Privacy', icon: Icons.shield_rounded),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 18, color: Colors.green.shade400),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Ergo is fully offline-first.',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• All quiz data is stored locally on your device.\n'
                      '• No user accounts, no tracking, no analytics.\n'
                      '• Internet is only used to browse & download quiz packs from the Store.\n'
                      '• No personal data is ever collected or transmitted.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Tech Stack ──
          _SectionHeader(title: 'Tech Stack', icon: Icons.layers_rounded),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              _StackRow(name: 'Flutter', detail: 'UI Framework'),
              const Divider(height: 1),
              _StackRow(name: 'Riverpod', detail: 'State Management'),
              const Divider(height: 1),
              _StackRow(name: 'SQLite (sqflite)', detail: 'Local Database'),
              const Divider(height: 1),
              _StackRow(name: 'GoRouter', detail: 'Declarative Routing'),
              const Divider(height: 1),
              _StackRow(
                  name: 'FL Chart + Heatmap', detail: 'Analytics Visuals'),
            ],
          ),

          const SizedBox(height: 20),

          // ── Open Source ──
          _SectionHeader(title: 'Open Source', icon: Icons.favorite_rounded),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ergo is open source and always will be.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Licensed under MIT. Contributions are welcome!\n'
                      'Star the repo, submit a PR, or create a DLC quiz pack.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _openUrl('https://github.com/dev-Aatif/ergo'),
                        icon: const Icon(Icons.star_border_rounded, size: 18),
                        label: const Text('Star on GitHub'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Made with ❤️ by Aatif',
              style: TextStyle(
                fontSize: 12,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Helper Widgets ──

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _CardRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon,
              size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: onTap != null
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.open_in_new_rounded,
                size: 14, color: Theme.of(context).colorScheme.primary),
          ],
        ],
      ),
    );

    return onTap != null ? InkWell(onTap: onTap, child: content) : content;
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _StackRow extends StatelessWidget {
  final String name;
  final String detail;

  const _StackRow({required this.name, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(name,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(detail,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
