import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/analytics_provider.dart';
// Note: Actual export/import requires a package like file_picker or share_plus in a real app,
// but for the MVP architecture, we demonstrate the scaffolding.

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          analyticsAsync.when(
            data: (data) => Card(
              elevation: 0,
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatRow('Total Quizzes', '${data.totalQuizzes}',
                        Icons.library_books),
                    const Divider(height: 32),
                    _buildStatRow(
                        'Average Accuracy',
                        '${data.averageAccuracy.toStringAsFixed(1)}%',
                        Icons.track_changes),
                    const Divider(height: 32),
                    _buildStatRow(
                        'Time Spent',
                        _formatDuration(data.totalTimeSpentSeconds),
                        Icons.timer),
                  ],
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading stats: $e'),
          ),
          const SizedBox(height: 32),
          const Text(
            'Data Management',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Progress (Backup)'),
            subtitle: const Text('Save your stats to a file.'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Exporting db... (Mocked for MVP)')));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Import Progress'),
            subtitle: const Text('Restore from a previous backup.'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Importing db... (Mocked for MVP)')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 28, color: Colors.blueGrey),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 18)),
        ),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
