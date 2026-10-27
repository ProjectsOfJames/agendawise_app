import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'agenda_bottom_nav.dart';

/// Persistent shell: tab content above, bottom nav with mic below.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AgendaBottomNav(
        currentIndex: navigationShell.currentIndex,
        onSelect: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        onMic: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice input is added in later')),
        ),
      ),
    );
  }
}
