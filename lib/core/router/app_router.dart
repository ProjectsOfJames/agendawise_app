import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/ui/create_account_screen.dart';
import '../../features/account/ui/edit_account_screens.dart';
import '../../features/account/ui/forgot_password_screen.dart';
import '../../features/account/ui/privacy_notice_screen.dart';
import '../../features/account/ui/sign_in_screen.dart';
import '../../features/admin/domain/admin_models.dart';
import '../../features/admin/ui/log_viewer_screen.dart';
import '../../features/admin/ui/manage_admins_screen.dart';
import '../../features/alarms/ui/alarm_form_screen.dart';
import '../../features/alarms/ui/alarm_ringing_screen.dart';
import '../../features/alarms/ui/alarms_screen.dart';
import '../../features/calendar/ui/calendar_screen.dart';
import '../../features/calendar/ui/event_form_screen.dart';
import '../../features/categories/presentation/category_management_screen.dart';
import '../../features/challenges/ui/challenge_screen.dart';
import '../../features/profile/ui/profile_screen.dart';
import '../../features/tasks/presentation/task_detail_screen.dart';
import '../../features/todo/ui/todo_screen.dart';
import '../../features/voice/ui/voice_confirm_screen.dart';
import '../../features/voice/ui/voice_fallback_screen.dart';
import '../../features/voice/ui/voice_listening_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../cloud/activity_actions.dart';

abstract final class AppRoutes {
  static const calendar = '/calendar';
  static const todo = '/todo';
  static const alarms = '/alarms';
  static const profile = '/profile';
  static const newTask = '/task/new';
  static const categories = '/categories';

  static String task(String id) => '/task/$id';

  static String event(String id) => '/event/$id';

  static const newAlarm = '/alarm/new';

  static String alarm(String id) => '/alarm/$id';

  static String ringing(String alarmId, int snoozesUsed) =>
      '/ringing/$alarmId?snoozes=$snoozesUsed';

  static String challenge(String alarmId) => '/challenge/$alarmId';

  static const signIn = '/account/sign-in';
  static const createAccount = '/account/create';
  static const forgotPassword = '/account/forgot-password';
  static const editName = '/account/name';
  static const editEmail = '/account/email';
  static const changePassword = '/account/password';
  static const privacyNotice = '/privacy';
  static const manageAdmins = '/admin/manage';
  static const myActivity = '/activity';
  static const voice = '/voice';
  static const voiceConfirm = '/voice/confirm';
  static const voiceFallback = '/voice/fallback';

  /// Admin log viewer, optionally opened with a date range and one action.
  static String adminLogs({DatePreset? preset, ActivityAction? action}) {
    final query = [
      if (preset != null) 'preset=${preset.name}',
      if (action != null) 'action=${action.wire}',
    ].join('&');
    return query.isEmpty ? '/admin/logs' : '/admin/logs?$query';
  }

  /// New event form with [day] preselected.
  static String newEvent(DateTime day) =>
      '/event/new?date=${day.year}-${day.month}-${day.day}';
}

DateTime? _parseDay(String? text) {
  final parts = text?.split('-').map(int.tryParse).toList();
  if (parts == null || parts.length != 3 || parts.contains(null)) return null;
  return DateTime(parts[0]!, parts[1]!, parts[2]!);
}

LogFilter _filterFrom(Map<String, String> query) {
  final preset = DatePreset.values
      .where((p) => p.name == query['preset'])
      .firstOrNull;
  final action = ActivityAction.fromWire(query['action']);
  return LogFilter(
    datePreset: preset ?? DatePreset.last7Days,
    actions: {?action},
  );
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
      // Declared before '/event/:id' so "new" is not read as an id
      GoRoute(
        path: '/event/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => EventFormScreen(
          initialDate: _parseDay(state.uri.queryParameters['date']),
        ),
      ),
      GoRoute(
        path: '/event/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            EventFormScreen(eventId: state.pathParameters['id']),
      ),
      // Declared before '/alarm/:id' so "new" is not read as an id
      GoRoute(
        path: AppRoutes.newAlarm,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AlarmFormScreen(),
      ),
      GoRoute(
        path: '/alarm/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            AlarmFormScreen(alarmId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/ringing/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AlarmRingingScreen(
          alarmId: state.pathParameters['id']!,
          snoozesUsed:
              int.tryParse(state.uri.queryParameters['snoozes'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/challenge/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ChallengeScreen(alarmId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.createAccount,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.editName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditNameScreen(),
      ),
      GoRoute(
        path: AppRoutes.editEmail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyNotice,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyNoticeScreen(),
      ),
      GoRoute(
        path: AppRoutes.voice,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VoiceListeningScreen(),
      ),
      GoRoute(
        path: AppRoutes.voiceConfirm,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra;
          return args is VoiceConfirmArgs
              ? VoiceConfirmScreen(args: args)
              : const VoiceFallbackScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.voiceFallback,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final heard = state.extra;
          return VoiceFallbackScreen(heard: heard is String ? heard : '');
        },
      ),
      GoRoute(
        path: '/admin/logs',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            LogViewerScreen(initial: _filterFrom(state.uri.queryParameters)),
      ),
      GoRoute(
        path: AppRoutes.manageAdmins,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageAdminsScreen(),
      ),
      GoRoute(
        path: AppRoutes.myActivity,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LogViewerScreen(
          initial: LogFilter(datePreset: DatePreset.last30Days),
          ownOnly: true,
        ),
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
