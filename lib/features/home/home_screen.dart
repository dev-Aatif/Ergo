import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/home_provider.dart';
import 'providers/streak_provider.dart';
import '../../core/audio/audio_service.dart';
import '../../core/utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          streakAsync.when(
            data: (streakData) => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department,
                      color: streakData.currentStreak > 0
                          ? Colors.orange
                          : Colors.grey),
                  const SizedBox(width: 4),
                  Text('${streakData.currentStreak}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text(
                'Your bookshelf is empty.\nDownload a subject to get started!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Streak card
              SliverToBoxAdapter(
                child: streakAsync.when(
                  data: (streakData) => _StreakCard(data: streakData),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ),

              // Category grid
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categories[index];
                      final color = safeParseColor(category.accentColor);

                      return InkWell(
                        onTap: () {
                          ref.read(audioServiceProvider).playClick();
                          context.pushNamed(
                            'category',
                            pathParameters: {'id': category.id},
                            extra: {'color': category.accentColor},
                          );
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                                color: color.withValues(alpha: 0.1),
                                width: 1.5),
                          ),
                          color: color.withValues(alpha: 0.05),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  getIconForName(category.iconName),
                                  size: 38,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to review',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: categories.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

// ── Streak Card ──

class _StreakCard extends StatelessWidget {
  final StreakData data;
  const _StreakCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = data.currentStreak > 0;
    final fireColor = isActive ? Colors.orange : Colors.grey;

    String motivationalText;
    if (data.currentStreak == 0) {
      motivationalText = 'Play a quiz to start your streak!';
    } else if (data.currentStreak >= data.bestStreak &&
        data.currentStreak > 1) {
      motivationalText = 'You\'re at your all-time best! 🏆';
    } else if (data.currentStreak >= 7) {
      motivationalText = 'Incredible dedication! 🔥';
    } else if (data.currentStreak >= 3) {
      motivationalText = 'Keep it going! 💪';
    } else {
      motivationalText = 'Don\'t break the chain!';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              fireColor.withValues(alpha: 0.08),
              fireColor.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: fireColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Current streak
                Icon(Icons.local_fire_department, color: fireColor, size: 28),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.currentStreak} day${data.currentStreak == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(motivationalText,
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                const Spacer(),
                // Best streak
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Best: ${data.bestStreak}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Text('days',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 14-day dot grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(14, (i) {
                final dayIndex = 13 - i; // reverse so oldest is left
                final played = dayIndex < data.last14Days.length
                    ? data.last14Days[dayIndex]
                    : false;
                return Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: played
                        ? fireColor.withValues(alpha: 0.7)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('14 days ago',
                    style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5))),
                Text('Today',
                    style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
