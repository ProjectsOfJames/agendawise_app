import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alarms/ui/alarms_screen.dart';
import '../../features/calendar/ui/calendar_screen.dart';
import '../../features/categories/presentation/category_management_screen.dart';
import '../../features/profile/ui/profile_screen.dart';
import '../../features/tasks/presentation/task_detail_screen.dart';
import '../../features/todo/ui/todo_screen.dart';
import '../../shared/widgets/app_shell.dart';

abstract final class AppRoutes {
  static const calendar = '/calendar';
  static const todo = '/todo';
  static const alarms = '/alarms';
  static const profile = '/profile';
  static const newTask = '/task/new';
  static const categories = '/categories';

  static String task(String id) => '/task/$id';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Tabs live in a stateful shell with the bottom bar; every other screen is
/// pushed on the root navigator so it covers the bar.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.calendar,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.calendar,
              builder: (context, state) => const CalendarScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.todo,
              builder: (context, state) => const TodoScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.alarms,
              builder: (context, state) => const AlarmsScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: AppRoutes.profile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      // Declared before '/task/:id' so "new" is not read as an id
      GoRoute(
        path: AppRoutes.newTask,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TaskDetailScreen(),
      ),
      GoRoute(
        path: '/task/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            TaskDetailScreen(taskId: state.pathParameters['id']),
      ),
      GoRoute(
        path: AppRoutes.categories,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoryManagementScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
