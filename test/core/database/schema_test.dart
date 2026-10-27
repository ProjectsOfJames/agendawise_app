import 'package:agendawise/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('foreign keys are enabled on open', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.first, 1);
  });

  test('all nine tables exist', () async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();
    expect(names, {
      'users',
      'app_settings',
      'categories',
      'alarms',
      'alarm_challenges',
      'calendar_events',
      'tasks',
      'notes',
      'interaction_logs',
    });
  });

  test('documented indexes exist', () async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name LIKE 'idx_%'",
        )
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();
    expect(names, {
      'idx_tasks_done_due',
      'idx_tasks_category',
      'idx_events_start',
      'idx_alarms_active',
      'idx_notes_task',
      'idx_logs_type_created',
    });
  });

  test('timestamps are stored as epoch milliseconds', () async {
    final at = DateTime(2026, 11, 2, 9, 30);
    await db.into(db.tasks).insert(
          TasksCompanion.insert(id: 't', title: 'Report', createdAt: at),
        );
    final row = await db
        .customSelect("SELECT created_at FROM tasks WHERE id = 't'")
        .getSingle();
    expect(row.read<int>('created_at'), at.millisecondsSinceEpoch);
  });
}
