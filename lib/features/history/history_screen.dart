import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (stats) {
          if (stats.totalQuizzesTaken == 0 && selectedCategory == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.query_stats,
                      size: 80,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No Data Yet', style: theme.textTheme.titleLarge),
                  const Text('Complete some quizzes to build your analytics!'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category Filter
                if (stats.categoryBreakdown.isNotEmpty) ...[
                  _buildCategoryFilter(context, ref, stats),
                  const SizedBox(height: 20),
                ],

                // Metric cards
                _buildMetricsGrid(context, stats),
                const SizedBox(height: 32),

                // Heatmap
                Text('Activity Flow',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: HeatMap(
                      datasets: stats.heatMapData,
                      colorMode: ColorMode.opacity,
                      showText: false,
                      scrollable: true,
                      colorsets: {
                        1: theme.colorScheme.primary,
                      },
                      startDate:
                          DateTime.now().subtract(const Duration(days: 60)),
                      endDate: DateTime.now(),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Performance Trend Chart with touch tooltips
                Text('Performance Trend',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LineChart(_buildChartData(theme, stats)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Category Breakdown
                if (stats.categoryBreakdown.isNotEmpty &&
                    selectedCategory == null) ...[
                  Text('Category Breakdown',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...stats.categoryBreakdown.entries.map(
                    (e) => _buildCategoryCard(context, e.value),
                  ),
                  const SizedBox(height: 32),
                ],

                // Recent Attempts
                Text('Recent Attempts',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...stats.recentAttempts.reversed.take(10).map(
                      (attempt) => _buildAttemptTile(context, attempt),
                    ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter(
      BuildContext context, WidgetRef ref, HistoryStats stats) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedCategoryProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selected,
          isExpanded: true,
          hint: const Text('All Categories'),
          icon: const Icon(Icons.filter_list),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Categories'),
            ),
            ...stats.categoryBreakdown.entries.map(
              (e) => DropdownMenuItem<String?>(
                value: e.key,
                child: Text(e.value.categoryName),
              ),
            ),
          ],
          onChanged: (value) {
            ref.read(selectedCategoryProvider.notifier).state = value;
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryStats catStats) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(catStats.categoryName,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                      '${catStats.quizCount} quizzes • ${catStats.avgTime.toStringAsFixed(1)}s avg',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getAccuracyColor(catStats.accuracy)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(catStats.accuracy * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getAccuracyColor(catStats.accuracy),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptTile(BuildContext context, dynamic attempt) {
    final theme = Theme.of(context);
    final pct = attempt.totalQuestions > 0
        ? (attempt.score / attempt.totalQuestions * 100)
        : 0.0;
    final dateStr =
        '${attempt.date.day}/${attempt.date.month}/${attempt.date.year}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: _getAccuracyColor(pct / 100).withValues(alpha: 0.15),
          child: Text(
            '${pct.toInt()}',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getAccuracyColor(pct / 100)),
          ),
        ),
        title: Text('${attempt.score}/${attempt.totalQuestions} correct',
            style: theme.textTheme.bodyMedium),
        subtitle: Text('$dateStr • ${attempt.timeTakenSeconds}s',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        trailing: Icon(
          pct >= 80
              ? Icons.star
              : (pct >= 50 ? Icons.star_half : Icons.star_border),
          color: Colors.amber,
          size: 20,
        ),
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green.shade400;
    if (accuracy >= 0.5) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  Widget _buildMetricsGrid(BuildContext context, HistoryStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricCard(
          title: 'Win Rate',
          value: '${(stats.globalAccuracy * 100).toStringAsFixed(1)}%',
          subtitle: 'Global Accuracy',
          icon: Icons.track_changes,
          color: Colors.green.shade400,
        ),
        _MetricCard(
          title: 'Pace',
          value: '${stats.averageTimePerQuestion.toStringAsFixed(1)}s',
          subtitle: 'Avg time per question',
          icon: Icons.timer,
          color: Colors.blue.shade400,
        ),
        _MetricCard(
          title: 'Volume',
          value: '${stats.totalQuestionsAnswered}',
          subtitle: 'Questions cleared',
          icon: Icons.library_add_check,
          color: Colors.purple.shade400,
        ),
        _MetricCard(
          title: 'Peak',
          value: '${(stats.bestScorePercentage * 100).toStringAsFixed(0)}%',
          subtitle: 'Highest score',
          icon: Icons.emoji_events,
          color: Colors.orange.shade400,
        ),
      ],
    );
  }

  LineChartData _buildChartData(ThemeData theme, HistoryStats stats) {
    List<FlSpot> spots = [];
    for (int i = 0; i < stats.movingAverageScoring.length; i++) {
      spots.add(FlSpot(i.toDouble(), stats.movingAverageScoring[i] * 100));
    }

    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)}%',
                TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 25,
            getTitlesWidget: (value, meta) {
              return Text('${value.toInt()}%',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (spots.length - 1 <= 0 ? 1 : spots.length - 1).toDouble(),
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots.isEmpty ? const [FlSpot(0, 0)] : spots,
          isCurved: true,
          color: theme.colorScheme.primary,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface)),
              Text(subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
