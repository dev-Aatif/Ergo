import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/category/category_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/storefront/storefront_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/settings/about_screen.dart';
import '../ui/main_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(navigationShell: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/storefront',
            name: 'storefront',
            builder: (context, state) => const StorefrontScreen(),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            builder: (context, state) => const HistoryScreen(),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/category/:id',
        name: 'category',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          final colorHex = extra?['color'] as String? ?? '#607D8B';

          return CategoryScreen(
            categoryId: id,
            colorHex: colorHex,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/quiz/:subjectId',
        name: 'quiz',
        builder: (context, state) {
          final subjectId = state.pathParameters['subjectId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final colorHex = extra?['color'] as String? ?? '#607D8B';

          return QuizScreen(
            subjectId: subjectId,
            colorHex: colorHex,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
});
