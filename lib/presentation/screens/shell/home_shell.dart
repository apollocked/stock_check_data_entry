import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// The signed-in app frame: the tabs and the bottom navigation bar.
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  final Widget child;

  const HomeShell({super.key, required this.shell, required this.child});

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2_rounded),
      label: 'Inventory',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights_rounded),
      label: 'Reports',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_rounded),
      selectedIcon: Icon(Icons.history_toggle_off_rounded),
      label: 'History',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        destinations: _destinations,
        onDestinationSelected: (index) {
          HapticFeedback.selectionClick();
          // Tapping the current tab again returns to its first screen.
          shell.goBranch(index, initialLocation: index == shell.currentIndex);
        },
      ),
    );
  }
}
