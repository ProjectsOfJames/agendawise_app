import 'dart:convert';

import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/features/backup/data/backup_repository.dart';
import 'package:agendawise/features/backup/domain/backup_format.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

const _at = 1793577600000; // 2026-11-02 00:00 UTC in epoch milliseconds

Future<void> _seed(AppDatabase db) async {
  final statements = [
    "INSERT INTO users (id, full_name, email, password_hash, salt, created_at) "
        "VALUES ('u1', 'Thandi', 'thandi@example.com', '', '', $_at)",
    "INSERT INTO categories (id, name, colour) VALUES ('c1', 'Work', '#FF0000')",
    "INSERT INTO categories (id, name, colour) VALUES ('c2', 'Home', '#00FF00')",
    "INSERT INTO alarms (id, title, hour, minute, repeat_days, snooze_minutes, "
        "snooze_limit, sound_ref, vibrate, is_active, ring_on, created_at, "
        "updated_at) VALUES ('a1', 'Wake', 6, 30, 31, 10, 3, 'tone_2', 1, 1, "
        "NULL, $_at, $_at)",
    "INSERT INTO alarms (id, hour, minute, ring_on, created_at, updated_at) "
        "VALUES ('a2', 9, 0, $_at, $_at, $_at)",
    "INSERT INTO alarm_challenges (id, alarm_id, challenge_type, difficulty) "
        "VALUES ('ch1', 'a1', 'maths', 3)",
    "INSERT INTO calendar_events (id, title, start_at, end_at, is_all_day, "
        "location, colour, reminder_minutes_before, repeat_rule, is_auto, "
        "created_at) VALUES ('e1', 'Standup', $_at, ${_at + 900000}, 0, "
        "'Room 1, \"Blue\"', '#3366FF', 10, 'weekly', 0, $_at)",
    "INSERT INTO tasks (id, title, priority, due_at, is_all_day, is_done, "
        "completed_at, category_id, event_id, alarm_id, created_at) VALUES "
        "('t1', 'Report ✓', 'high', $_at, 0, 1, $_at, 'c1', 'e1', 'a2', $_at)",
    "INSERT INTO tasks (id, title, created_at) VALUES ('t2', 'Milk', $_at)",
    "INSERT INTO notes (id, task_id, body, created_at) VALUES "
        "('n1', 't1', 'Line one\nLine two', $_at)",
    "INSERT INTO interaction_logs (id, event_type, alarm_id, challenge_type, "
        "difficulty, duration_ms, success, created_at) VALUES "
        "('l1', 'challenge_completed', 'a1', 'maths', 3, 12000, 1, $_at)",
    "INSERT INTO app_settings (key, value) VALUES ('theme_mode', 'dark')",
    "INSERT INTO app_settings (key, value) VALUES "
        "('account_last_active_date', '2026-11-02')",
    "INSERT INTO app_settings (key, value) VALUES ('battery_prompt_shown', 'true')",
  ];
  for (final sql in statements) {
    await db.customStatement(sql);
  }
}

Future<Map<String, List<Map<String, Object?>>>> _dump(AppDatabase db) async {
  final result = <String, List<Map<String, Object?>>>{};
  for (final table in [...backupTables, 'users']) {
    final rows = await db.customSelect('SELECT * FROM "$table"').get();
    final list = rows.map((r) => Map<String, Object?>.from(r.data)).toList()
      ..sort((a, b) => '${a['id'] ?? a['key']}'.compareTo('${b['id'] ?? b['key']}'));
    result[table] = list;
  }
  return result;
}

void main() {
  late AppDatabase source;
  late AppDatabase target;

  setUp(() {
    source = openTestDatabase();
    target = openTestDatabase();
  });
  tearDown(() async {
    await source.close();
    await target.close();
  });

  test('a restored database is identical to the exported one', () async {
    await _seed(source);
    final json = await BackupRepository(source).exportJson(DateTime(2026, 11, 2));

    final repo = BackupRepository(target);
    await repo.restore(repo.parse(json));

    final before = await _dump(source);
    final after = await _dump(target);
    for (final table in backupTables.where((t) => t != 'app_settings')) {
      expect(after[table], before[table], reason: table);
    }
    expect(after['app_settings'], [
      {'key': 'theme_mode', 'value': 'dark'},
    ]);
    // The account is never part of a backup.
    expect(after['users'], isEmpty);
  });

  test('the backup has a header and leaves out the account and device '
      'settings', () async {
    await _seed(source);
    final decoded = jsonDecode(
            await BackupRepository(source).exportJson(DateTime.utc(2026, 11, 2)))
        as Map<String, dynamic>;
    expect(decoded['app'], backupAppName);
    expect(decoded['formatVersion'], backupFormatVersion);
    expect(decoded['schemaVersion'], source.schemaVersion);
    expect(decoded['exportedAt'], '2026-11-02T00:00:00.000Z');
    final tables = decoded['tables'] as Map<String, dynamic>;
    expect(tables.keys, unorderedEquals(backupTables));
    expect(tables.containsKey('users'), isFalse);
    final settings = (tables['app_settings'] as List).cast<Map>();
    expect(settings.map((s) => s['key']), ['theme_mode']);
  });

  test('restoring replaces existing data but keeps the account and device '
      'settings', () async {
    await _seed(source);
    final json = await BackupRepository(source).exportJson(DateTime(2026, 11, 2));

    await target.customStatement(
        "INSERT INTO users (id, full_name, email, password_hash, salt, created_at) "
        "VALUES ('me', 'Sipho', 'sipho@example.com', '', '', $_at)");
    await target.customStatement(
        "INSERT INTO tasks (id, title, created_at) VALUES ('old', 'Old task', $_at)");
    await target.customStatement(
        "INSERT INTO app_settings (key, value) VALUES ('overlay_prompt_shown', 'true')");
    await target.customStatement(
        "INSERT INTO app_settings (key, value) VALUES ('theme_mode', 'light')");

    final repo = BackupRepository(target);
    await repo.restore(repo.parse(json));

    final after = await _dump(target);
    expect(after['tasks']!.map((t) => t['id']), ['t1', 't2']);
    expect(after['users']!.single['id'], 'me');
    expect(after['app_settings'], [
      {'key': 'overlay_prompt_shown', 'value': 'true'},
      {'key': 'theme_mode', 'value': 'dark'},
    ]);
  });

  test('a backup with invalid rows changes nothing', () async {
    await target.customStatement(
        "INSERT INTO tasks (id, title, created_at) VALUES ('keep', 'Keep me', $_at)");
    final repo = BackupRepository(target);
    final bad = repo.parse(jsonEncode({
      'app': backupAppName,
      'formatVersion': 1,
      'schemaVersion': 2,
      'tables': {
        'alarms': [
          {'id': 'x', 'hour': 25, 'minute': 0, 'created_at': _at, 'updated_at': _at},
        ],
      },
    }));

    await expectLater(repo.restore(bad), throwsA(isA<BackupException>()));
    final tasks = await target.customSelect('SELECT id FROM tasks').get();
    expect(tasks.map((r) => r.data['id']), ['keep']);
  });

  group('validation', () {
    late BackupRepository repo;
    setUp(() => repo = BackupRepository(target));

    Matcher rejectsWith(String text) => throwsA(isA<BackupException>()
        .having((e) => e.message, 'message', contains(text)));

    test('rejects files that are not backups', () {
      expect(() => repo.parse('not json'), rejectsWith('not an AgendaWise'));
      expect(() => repo.parse('[]'), rejectsWith('not an AgendaWise'));
      expect(() => repo.parse('{"app": "Other", "tables": {}}'),
          rejectsWith('not an AgendaWise'));
    });

    test('rejects backups from a newer version', () {
      final json = jsonEncode({
        'app': backupAppName,
        'formatVersion': 1,
        'schemaVersion': target.schemaVersion + 1,
        'tables': <String, Object>{},
      });
      expect(() => repo.parse(json), rejectsWith('newer version'));
    });

    test('rejects unknown tables and columns', () {
      String backup(Map<String, Object> tables) => jsonEncode({
            'app': backupAppName,
            'formatVersion': 1,
            'schemaVersion': 2,
            'tables': tables,
          });
      expect(() => repo.parse(backup({'users': []})),
          rejectsWith('unknown table'));
      expect(
        () => repo.parse(backup({
          'tasks': [
            {'id': 't', 'title': 'x', 'created_at': 1, 'secret': 'y'},
          ],
        })),
        rejectsWith('unknown column'),
      );
    });

    test('accepts an older schema without newer columns', () async {
      final json = jsonEncode({
        'app': backupAppName,
        'formatVersion': 1,
        'schemaVersion': 1,
        'tables': {
          'alarms': [
            {'id': 'a', 'hour': 7, 'minute': 15, 'created_at': _at, 'updated_at': _at},
          ],
        },
      });
      await repo.restore(repo.parse(json));
      final alarm = (await target.customSelect('SELECT * FROM alarms').get())
          .single
          .data;
      expect(alarm['ring_on'], isNull);
      expect(alarm['snooze_minutes'], 5);
    });

    test('device settings in a backup are ignored', () {
      final contents = repo.parse(jsonEncode({
        'app': backupAppName,
        'formatVersion': 1,
        'schemaVersion': 2,
        'tables': {
          'app_settings': [
            {'key': 'account_last_active_date', 'value': '2020-01-01'},
            {'key': 'theme_mode', 'value': 'dark'},
          ],
        },
      }));
      expect(contents.tables['app_settings'], [
        {'key': 'theme_mode', 'value': 'dark'},
      ]);
    });
  });
}
