import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/home_provider.dart';
import 'providers/streak_provider.dart';
import '../../core/audio/audio_service.dart';

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
            data: (streak) => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department,
                      color: streak > 0 ? Colors.orange : Colors.grey),
                  const SizedBox(width: 4),
                  Text('$streak',
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

          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final color = Color(
                  int.parse(category.accentColor.replaceFirst('#', '0xFF')));

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
                    side: BorderSide(color: color.withOpacity(0.1), width: 1.5),
                  ),
                  color: color.withOpacity(0.05),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForCategory(category.name),
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
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to review',
                        style: TextStyle(
                          fontSize: 12,
                          color: color.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
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
      default:
        return Icons.menu_book_rounded;
    }
  }
}
