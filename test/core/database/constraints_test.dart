import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/core/domain/challenge_type.dart';
import 'package:agendawise/core/domain/interaction_event_type.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

final _at = DateTime(2026, 11, 2, 9);

AlarmsCompanion _alarm(
  String id, {
  int hour = 7,
  int minute = 0,
  Value<int?> snoozeLimit = const Value.absent(),
  Value<int> repeatDays = const Value.absent(),
}) =>
    AlarmsCompanion.insert(
      id: id,
      hour: hour,
      minute: minute,
      snoozeLimit: snoozeLimit,
      repeatDays: repeatDays,
      createdAt: _at,
      updatedAt: _at,
    );

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  final rejected = throwsA(isA<Exception>());

  group('domain checks', () {
    test('alarm hour and minute ranges', () async {
      await db.into(db.alarms).insert(_alarm('ok', hour: 23, minute: 59));
      await expectLater(
          db.into(db.alarms).insert(_alarm('h', hour: 24)), rejected);
      await expectLater(
          db.into(db.alarms).insert(_alarm('m', minute: 60)), rejected);
    });

    test('snooze limit is null or 1 to 20', () async {
      await db.into(db.alarms).insert(_alarm('a', snoozeLimit: const Value(null)));
      await db.into(db.alarms).insert(_alarm('b', snoozeLimit: const Value(20)));
      await expectLater(
        db.into(db.alarms).insert(_alarm('c', snoozeLimit: const Value(0))),
        rejected,
      );
      await expectLater(
        db.into(db.alarms).insert(_alarm('d', snoozeLimit: const Value(21))),
        rejected,
      );
    });

    test('repeat mask is 0 to 127', () async {
      await expectLater(
        db.into(db.alarms).insert(_alarm('a', repeatDays: const Value(128))),
        rejected,
      );
    });

    test('alarm defaults match the design', () async {
      await db.into(db.alarms).insert(_alarm('a'));
      final alarm = await (db.select(db.alarms)
            ..where((a) => a.id.equals('a')))
          .getSingle();
      expect(alarm.snoozeMinutes, 5);
      expect(alarm.snoozeLimit, isNull);
      expect(alarm.soundRef, 'tone_1');
      expect(alarm.vibrate, isTrue);
      expect(alarm.isActive, isTrue);
      expect(alarm.repeatDays, 0);
    });

    test('raw insert without optional columns uses SQL defaults', () async {
      await db.customStatement(
        "INSERT INTO alarms (id, hour, minute, created_at, updated_at) "
        "VALUES ('raw', 6, 30, 0, 0)",
      );
      final alarm = await (db.select(db.alarms)
            ..where((a) => a.id.equals('raw')))
          .getSingle();
      expect(alarm.snoozeMinutes, 5);
      expect(alarm.soundRef, 'tone_1');
    });

    test('difficulty is 1 to 5', () async {
      await db.into(db.alarms).insert(_alarm('a'));
      await expectLater(
        db.into(db.alarmChallenges).insert(
              AlarmChallengesCompanion.insert(
                id: 'c',
                alarmId: 'a',
                challengeType: ChallengeType.maths,
                difficulty: const Value(6),
              ),
            ),
        rejected,
      );
    });

    test('category name is unique ignoring case and colour is #RRGGBB',
        () async {
      await db.into(db.categories).insert(
            CategoriesCompanion.insert(id: '1', name: 'Work', colour: '#06B6D4'),
          );
      await expectLater(
        db.into(db.categories).insert(
              CategoriesCompanion.insert(id: '2', name: 'work', colour: '#06B6D4'),
            ),
        rejected,
      );
      await expectLater(
        db.into(db.categories).insert(
              CategoriesCompanion.insert(id: '3', name: 'Home', colour: 'red'),
            ),
        rejected,
      );
    });

    test('blank names and titles are rejected', () async {
      await expectLater(
        db.into(db.tasks).insert(
              TasksCompanion.insert(id: 't', title: '   ', createdAt: _at),
            ),
        rejected,
      );
      await expectLater(
        db.into(db.categories).insert(
              CategoriesCompanion.insert(id: 'c', name: ' ', colour: '#000000'),
            ),
        rejected,
      );
    });

    test('event cannot end before it starts', () async {
      await expectLater(
        db.into(db.calendarEvents).insert(
              CalendarEventsCompanion.insert(
                id: 'e',
                startAt: _at,
                endAt: _at.subtract(const Duration(minutes: 1)),
                colour: '#7C5CFC',
                createdAt: _at,
              ),
            ),
        rejected,
      );
    });

    test('task completion time exists only when done', () async {
      await expectLater(
        db.into(db.tasks).insert(
              TasksCompanion.insert(
                id: 'a',
                title: 'Done without time',
                isDone: const Value(true),
                createdAt: _at,
              ),
            ),
        rejected,
      );
      await expectLater(
        db.into(db.tasks).insert(
              TasksCompanion.insert(
                id: 'b',
                title: 'Open with time',
                completedAt: Value(_at),
                createdAt: _at,
              ),
            ),
        rejected,
      );
    });

    test('an alarm has at most one challenge', () async {
      await db.into(db.alarms).insert(_alarm('a'));
      await db.into(db.alarmChallenges).insert(
            AlarmChallengesCompanion.insert(
              id: 'c1',
              alarmId: 'a',
              challengeType: ChallengeType.maths,
            ),
          );
      await expectLater(
        db.into(db.alarmChallenges).insert(
              AlarmChallengesCompanion.insert(
                id: 'c2',
                alarmId: 'a',
                challengeType: ChallengeType.shake,
              ),
            ),
        rejected,
      );
    });

    test('foreign key to a missing row is rejected', () async {
      await expectLater(
        db.into(db.tasks).insert(
              TasksCompanion.insert(
                id: 't',
                title: 'Orphan',
                categoryId: const Value('missing'),
                createdAt: _at,
              ),
            ),
        rejected,
      );
    });
  });

  group('delete behaviour', () {
    test('deleting an alarm deletes its challenge and keeps its logs',
        () async {
      await db.into(db.alarms).insert(_alarm('a'));
      await db.into(db.alarmChallenges).insert(
            AlarmChallengesCompanion.insert(
              id: 'c',
              alarmId: 'a',
              challengeType: ChallengeType.memory,
            ),
          );
      await db.into(db.interactionLogs).insert(
            InteractionLogsCompanion.insert(
              id: 'l',
              eventType: InteractionEventType.alarmDismissed,
              alarmId: const Value('a'),
              createdAt: _at,
            ),
          );

      await (db.delete(db.alarms)..where((a) => a.id.equals('a'))).go();

      expect(await db.select(db.alarmChallenges).get(), isEmpty);
      final logs = await db.select(db.interactionLogs).get();
      expect(logs, hasLength(1));
      expect(logs.single.alarmId, isNull);
    });

    test('deleting a category leaves its tasks uncategorised', () async {
      await db.into(db.categories).insert(
            CategoriesCompanion.insert(id: 'c', name: 'Work', colour: '#06B6D4'),
          );
      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: 't',
              title: 'Report',
              categoryId: const Value('c'),
              createdAt: _at,
            ),
          );

      await (db.delete(db.categories)..where((c) => c.id.equals('c'))).go();

      final task = await db.select(db.tasks).getSingle();
      expect(task.categoryId, isNull);
    });

    test('deleting an event unlinks its task', () async {
      await db.into(db.calendarEvents).insert(
            CalendarEventsCompanion.insert(
              id: 'e',
              startAt: _at,
              endAt: _at.add(const Duration(hours: 1)),
              colour: '#7C5CFC',
              isAuto: const Value(true),
              createdAt: _at,
            ),
          );
      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: 't',
              title: 'Report',
              eventId: const Value('e'),
              createdAt: _at,
            ),
          );

      await (db.delete(db.calendarEvents)..where((e) => e.id.equals('e')))
          .go();

      final task = await db.select(db.tasks).getSingle();
      expect(task.eventId, isNull);
    });

    test('deleting a task deletes its notes and keeps its logs', () async {
      await db.into(db.tasks).insert(
            TasksCompanion.insert(id: 't', title: 'Report', createdAt: _at),
          );
      await db.into(db.notes).insert(
            NotesCompanion.insert(
              id: 'n',
              taskId: 't',
              body: 'Attach figures',
              createdAt: _at,
            ),
          );
      await db.into(db.interactionLogs).insert(
            InteractionLogsCompanion.insert(
              id: 'l',
              eventType: InteractionEventType.taskCompleted,
              taskId: const Value('t'),
              createdAt: _at,
            ),
          );

      await (db.delete(db.tasks)..where((t) => t.id.equals('t'))).go();

      expect(await db.select(db.notes).get(), isEmpty);
      final log = await db.select(db.interactionLogs).getSingle();
      expect(log.taskId, isNull);
    });

    test('clearUserData keeps the account', () async {
      await db.into(db.users).insert(
            UsersCompanion.insert(
              id: 'u',
              fullName: 'Thandi',
              email: 'thandi@example.com',
              passwordHash: 'h',
              salt: 's',
              createdAt: _at,
            ),
          );
      await db.into(db.alarms).insert(_alarm('a'));
      await db.into(db.tasks).insert(
            TasksCompanion.insert(id: 't', title: 'Report', createdAt: _at),
          );

      await db.clearUserData();

      expect(await db.select(db.alarms).get(), isEmpty);
      expect(await db.select(db.tasks).get(), isEmpty);
      expect(await db.select(db.users).get(), hasLength(1));
    });
  });
}
