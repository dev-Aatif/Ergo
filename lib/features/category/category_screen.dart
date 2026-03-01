import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/category_provider.dart';

class CategoryScreen extends ConsumerWidget {
  final String categoryId;
  final String colorHex;

  const CategoryScreen({
    super.key,
    required this.categoryId,
    required this.colorHex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider(categoryId));
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: color),
      ),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(
                child: Text('No subjects found in this category.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: subjects.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Card(
                elevation: 0,
                color: color.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withOpacity(0.1), width: 1),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(subject.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: color),
                  ),
                  onTap: () {
                    context.pushNamed(
                      'quiz',
                      pathParameters: {'subjectId': subject.id},
                      extra: {'color': colorHex},
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: color)),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
