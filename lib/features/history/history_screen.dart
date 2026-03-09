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

                // ── Overview Metrics ──
                const _SectionHeader(title: 'Overview'),
                const SizedBox(height: 12),
                _buildOverviewGrid(context, stats),
                const SizedBox(height: 28),

                // ── Activity Heatmap ──
                const _SectionHeader(title: 'Activity Flow'),
                const SizedBox(height: 12),
                _buildHeatmap(context, stats),
                const SizedBox(height: 28),

                // ── Performance Trend ──
                const _SectionHeader(title: 'Performance Trend'),
                const SizedBox(height: 12),
                _buildPerformanceChart(context, stats),
                const SizedBox(height: 28),

                // ── Behavioral Insights ──
                if (stats.totalQuestionsAnswered > 0) ...[
                  const _SectionHeader(title: 'Behavioral Insights'),
                  const SizedBox(height: 12),
                  _buildBehavioralGrid(context, stats),
                  const SizedBox(height: 28),
                ],

                // ── Timing Analysis (Tier 2) ──
                if (stats.avgTimeCorrectMs > 0 ||
                    stats.avgTimeIncorrectMs > 0) ...[
                  const _SectionHeader(title: 'Timing Analysis'),
                  const SizedBox(height: 12),
                  _buildTimingGrid(context, stats),
                  const SizedBox(height: 28),
                ],

                // ── Chronotype ──
                if (stats.chronotypeAccuracy.isNotEmpty) ...[
                  const _SectionHeader(title: 'Best Time to Play'),
                  const SizedBox(height: 12),
                  _buildChronotypeChart(context, stats),
                  const SizedBox(height: 28),
                ],

                // ── Category Breakdown ──
                if (stats.categoryBreakdown.isNotEmpty) ...[
                  const _SectionHeader(title: 'Category Breakdown'),
                  const SizedBox(height: 12),
                  _buildCategoryBreakdown(context, stats),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Category Filter ──

  Widget _buildCategoryFilter(
      BuildContext context, WidgetRef ref, HistoryStats stats) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) =>
                  ref.read(selectedCategoryProvider.notifier).state = null,
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          ...stats.categoryBreakdown.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(entry.value.categoryName),
                  selected: selected == entry.key,
                  onSelected: (_) => ref
                      .read(selectedCategoryProvider.notifier)
                      .state = entry.key,
                  selectedColor:
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
              )),
        ],
      ),
    );
  }

  // ── Overview Grid ──

  Widget _buildOverviewGrid(BuildContext context, HistoryStats stats) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatTile(
          icon: Icons.quiz_outlined,
          label: 'Quizzes',
          value: '${stats.totalQuizzesTaken}',
          color: Colors.blue,
          hint: 'Total number of quizzes you\'ve completed.',
        ),
        _StatTile(
          icon: Icons.check_circle_outline,
          label: 'Accuracy',
          value: '${(stats.globalAccuracy * 100).toStringAsFixed(1)}%',
          color: Colors.green,
          hint:
              'Percentage of questions you answered correctly across all quizzes.',
        ),
        _StatTile(
          icon: Icons.help_outline,
          label: 'Questions',
          value: '${stats.totalQuestionsAnswered}',
          color: Colors.purple,
          hint: 'Total questions you\'ve answered across all quizzes.',
        ),
        _StatTile(
          icon: Icons.timer_outlined,
          label: 'Avg Pace',
          value: '${stats.averageTimePerQuestion.toStringAsFixed(1)}s',
          color: Colors.orange,
          hint: 'Average time you take per question in seconds.',
        ),
        _StatTile(
          icon: Icons.local_fire_department,
          label: 'Best Streak',
          value: '${stats.bestStreakEver}d',
          color: Colors.deepOrange,
          hint: 'Longest consecutive days you played quizzes.',
        ),
        _StatTile(
          icon: Icons.emoji_events_outlined,
          label: 'Best Score',
          value: '${(stats.bestScorePercentage * 100).toStringAsFixed(0)}%',
          color: Colors.amber,
          hint: 'Your highest accuracy in a single quiz session.',
        ),
        _StatTile(
          icon: Icons.speed,
          label: 'Fastest',
          value: stats.fastestQuizPace > 0
              ? '${stats.fastestQuizPace.toStringAsFixed(1)}s/Q'
              : '-',
          color: Colors.cyan,
          hint:
              'Fastest average pace you\'ve achieved in a quiz (seconds per question).',
        ),
        if (stats.mostPlayedSubject != null)
          _StatTile(
            icon: Icons.star_outline,
            label: 'Favorite',
            value: stats.mostPlayedSubject!,
            color: Colors.pink,
            isText: true,
            hint: 'The category you\'ve played the most quizzes in.',
          ),
      ],
    );
  }

  // ── Behavioral Grid ──

  Widget _buildBehavioralGrid(BuildContext context, HistoryStats stats) {
    final trend = stats.improvementTrend;
    final trendLabel = trend > 0
        ? '+${(trend * 100).toStringAsFixed(1)}%'
        : '${(trend * 100).toStringAsFixed(1)}%';

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatTile(
          icon: trend >= 0 ? Icons.trending_up : Icons.trending_down,
          label: '7-Day Trend',
          value: trendLabel,
          color: trend >= 0 ? Colors.green : Colors.red,
          hint:
              'How your accuracy changed in the last 7 days compared to the 7 days before that.',
        ),
        _StatTile(
          icon: Icons.autorenew,
          label: 'Return',
          value: stats.avgReturnHours > 0
              ? '${stats.avgReturnHours.toStringAsFixed(1)}h'
              : '-',
          color: Colors.teal,
          hint: 'Average time between your quiz sessions in hours.',
        ),
        _StatTile(
          icon: Icons.exit_to_app,
          label: 'Quit Rate',
          value: '${(stats.abandonmentRate * 100).toStringAsFixed(0)}%',
          color: Colors.grey,
          hint: 'Percentage of quizzes you quit early without completing.',
        ),
        _StatTile(
          icon: Icons.local_fire_department,
          label: 'Revenge',
          value: '${stats.revengeSessions}',
          color: Colors.red,
          hint:
              'Times you immediately retried after scoring below 50%. Shows determination!',
        ),
        if (stats.knowledgeVolatility > 0)
          _StatTile(
            icon: Icons.show_chart,
            label: 'Volatility',
            value: '${(stats.knowledgeVolatility * 100).toStringAsFixed(0)}%',
            color: Colors.amber[700]!,
            hint:
                'How much your scores vary. Low = consistent, High = unpredictable performance.',
          ),
      ],
    );
  }

  // ── Timing Grid (Tier 2) ──

  Widget _buildTimingGrid(BuildContext context, HistoryStats stats) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatTile(
          icon: Icons.check,
          label: 'Correct Pace',
          value: '${(stats.avgTimeCorrectMs / 1000).toStringAsFixed(1)}s',
          color: Colors.green,
          hint: 'Average time you take to answer questions you get right.',
        ),
        _StatTile(
          icon: Icons.close,
          label: 'Wrong Pace',
          value: '${(stats.avgTimeIncorrectMs / 1000).toStringAsFixed(1)}s',
          color: Colors.red,
          hint:
              'Average time you take on questions you get wrong. If faster than Correct Pace, you may be guessing.',
        ),
        if (stats.fatigueIndex != 0)
          _StatTile(
            icon: Icons.battery_alert_outlined,
            label: 'Fatigue',
            value:
                '${stats.fatigueIndex > 0 ? '-' : '+'}${(stats.fatigueIndex.abs() * 100).toStringAsFixed(0)}%',
            color: stats.fatigueIndex > 0.1 ? Colors.red : Colors.green,
            hint:
                'How much your accuracy drops from early to late questions. Negative = you get worse as quizzes go on.',
          ),
        _StatTile(
          icon: Icons.gps_fixed,
          label: 'Clutch',
          value: '${(stats.clutchAccuracy * 100).toStringAsFixed(0)}%',
          color: Colors.indigo,
          hint:
              'Your accuracy on the final question of each quiz. High = you finish strong under pressure!',
        ),
        if (stats.tiltFactor > 0)
          _StatTile(
            icon: Icons.psychology_alt,
            label: 'Tilt Factor',
            value: '${(stats.tiltFactor * 100).toStringAsFixed(0)}%',
            color: Colors.deepPurple,
            hint:
                'Chance of getting another wrong answer after 2+ consecutive wrong. High = mistakes spiral into more mistakes.',
          ),
      ],
    );
  }

  // ── Heatmap ──

  Widget _buildHeatmap(BuildContext context, HistoryStats stats) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: HeatMap(
          datasets: stats.heatMapData,
          colorMode: ColorMode.opacity,
          showText: false,
          scrollable: true,
          colorsets: {1: theme.colorScheme.primary},
          startDate: DateTime.now().subtract(const Duration(days: 60)),
          endDate: DateTime.now(),
          size: 20,
        ),
      ),
    );
  }

  // ── Performance Trend Chart ──

  Widget _buildPerformanceChart(BuildContext context, HistoryStats stats) {
    final theme = Theme.of(context);
    if (stats.movingAverageScoring.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 250,
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 0.25,
                    getTitlesWidget: (value, _) => Text(
                      '${(value * 100).toInt()}%',
                      style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                bottomTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: 1,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    stats.movingAverageScoring.length,
                    (i) => FlSpot(i.toDouble(), stats.movingAverageScoring[i]),
                  ),
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots
                      .map((spot) => LineTooltipItem(
                            '${(spot.y * 100).toInt()}%',
                            TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Chronotype Chart ──

  Widget _buildChronotypeChart(BuildContext context, HistoryStats stats) {
    final theme = Theme.of(context);
    final hours = stats.chronotypeAccuracy.keys.toList()..sort();

    if (hours.isEmpty) return const SizedBox.shrink();

    // Find best hour
    int bestHour = hours.first;
    double bestAcc = 0;
    for (final h in hours) {
      if (stats.chronotypeAccuracy[h]! > bestAcc) {
        bestAcc = stats.chronotypeAccuracy[h]!;
        bestHour = h;
      }
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'You perform best around '),
                  TextSpan(
                    text: '$bestHour:00',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary),
                  ),
                  TextSpan(
                    text:
                        ' with ${(bestAcc * 100).toStringAsFixed(0)}% accuracy',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1,
                  barTouchData: const BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                          final h = val.toInt();
                          if (hours.contains(h)) {
                            return Text('${h}h',
                                style: const TextStyle(fontSize: 9));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: hours
                      .map((h) => BarChartGroupData(
                            x: h,
                            barRods: [
                              BarChartRodData(
                                toY: stats.chronotypeAccuracy[h] ?? 0,
                                width: 12,
                                borderRadius: BorderRadius.circular(4),
                                color: h == bestHour
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                              ),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Breakdown ──

  Widget _buildCategoryBreakdown(BuildContext context, HistoryStats stats) {
    final theme = Theme.of(context);
    final entries = stats.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.quizCount.compareTo(a.value.quizCount));

    return Column(
      children: entries.map((entry) {
        final cat = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.categoryName,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${cat.quizCount} quizzes • ${(cat.accuracy * 100).toStringAsFixed(0)}% accuracy',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: cat.accuracy,
                        strokeWidth: 4,
                        color: theme.colorScheme.primary,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                      Text('${(cat.accuracy * 100).toInt()}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Widget Components ──

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isText;
  final String? hint;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isText = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final tileWidth = (screenWidth - 32 - 10) / 2; // 2 columns

    return SizedBox(
      width: tileWidth,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const Spacer(),
                if (hint != null)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(label),
                          content: Text(hint!),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Icon(Icons.info_outline_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isText ? 14 : 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
