import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatefulWidget {
  final Widget navigationShell;

  const MainLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  bool _isSwipingForward = true;

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/storefront')) return 1;
    if (location.startsWith('/history')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    setState(() {
      _isSwipingForward = index > currentIndex;
    });

    switch (index) {
      case 0:
        context.goNamed('home');
        break;
      case 1:
        context.goNamed('storefront');
        break;
      case 2:
        context.goNamed('history');
        break;
      case 3:
        context.goNamed('settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    final isSwipeable = currentIndex < 3;

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: isSwipeable
            ? (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! > 300 && currentIndex > 0) {
                  _onItemTapped(currentIndex - 1, context);
                }
                if (details.primaryVelocity! < -300 && currentIndex < 2) {
                  _onItemTapped(currentIndex + 1, context);
                }
              }
            : null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final slideIn = Tween<Offset>(
              begin: Offset(_isSwipingForward ? 1.0 : -1.0, 0),
              end: Offset.zero,
            ).animate(animation);

            final slideOut = Tween<Offset>(
              begin: Offset(_isSwipingForward ? -1.0 : 1.0, 0),
              end: Offset.zero,
            ).animate(animation);

            // The incoming widget uses slideIn, the outgoing uses slideOut
            if (child.key == ValueKey(widget.navigationShell.key)) {
              return SlideTransition(position: slideIn, child: child);
            }
            return SlideTransition(position: slideOut, child: child);
          },
          child: KeyedSubtree(
            key: ValueKey(currentIndex),
            child: widget.navigationShell,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Store',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
