import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/challenge_type.dart';
import '../domain/interaction_event_type.dart';
import '../domain/task_priority.dart';
import 'converters.dart';
import 'daos/alarms_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/events_dao.dart';
import 'daos/interaction_logs_dao.dart';
import 'daos/notes_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/tasks_dao.dart';
import 'daos/users_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

const _indexStatements = [
  'CREATE INDEX IF NOT EXISTS idx_tasks_done_due ON tasks (is_done, due_at)',
  'CREATE INDEX IF NOT EXISTS idx_tasks_category ON tasks (category_id)',
  'CREATE INDEX IF NOT EXISTS idx_events_start ON calendar_events (start_at)',
  'CREATE INDEX IF NOT EXISTS idx_alarms_active ON alarms (is_active)',
  'CREATE INDEX IF NOT EXISTS idx_notes_task ON notes (task_id)',
  'CREATE INDEX IF NOT EXISTS idx_logs_type_created '
      'ON interaction_logs (challenge_type, created_at)',
];

@DriftDatabase(
  tables: [
    Users,
    AppSettings,
    Categories,
    Alarms,
    AlarmChallenges,
    CalendarEvents,
    Tasks,
    Notes,
    InteractionLogs,
  ],
  daos: [
    UsersDao,
    SettingsDao,
    CategoriesDao,
    AlarmsDao,
    EventsDao,
    TasksDao,
    NotesDao,
    InteractionLogsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the on-device database file in app-private storage.
  AppDatabase.device() : super(driftDatabase(name: 'agendawise'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          for (final statement in _indexStatements) {
            await customStatement(statement);
          }
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(alarms, alarms.ringOn);
          }
        },
        beforeOpen: (details) async {
          // SQLite only enforces foreign keys when enabled per connection.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Deletes every row except the account, children first.
  Future<void> clearUserData() => transaction(() async {
        await delete(interactionLogs).go();
        await delete(notes).go();
        await delete(tasks).go();
        await delete(calendarEvents).go();
        await delete(alarmChallenges).go();
        await delete(alarms).go();
        await delete(categories).go();
        await delete(appSettings).go();
      });
}
