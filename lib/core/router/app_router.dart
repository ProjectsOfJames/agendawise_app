import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alarms/ui/alarms_screen.dart';
import '../../features/calendar/ui/calendar_screen.dart';
import '../../features/profile/ui/profile_screen.dart';
import '../../features/todo/ui/todo_screen.dart';
import '../../shared/widgets/app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/calendar',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/calendar',
              builder: (context, state) => const CalendarScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/todo',
              builder: (context, state) => const TodoScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/alarms',
              builder: (context, state) => const AlarmsScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: ProfileScreen(),
        ),
      ),
    ],
  );
});
