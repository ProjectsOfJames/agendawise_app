import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/core/domain/challenge_type.dart';
import 'package:agendawise/core/errors/validation_exception.dart';
import 'package:agendawise/core/utils/id_generator.dart';
import 'package:agendawise/features/alarms/application/alarm_controller.dart';
import 'package:agendawise/features/alarms/application/alarm_scheduler.dart';
import 'package:agendawise/features/alarms/data/alarm_repository.dart';
import 'package:agendawise/features/alarms/domain/alarm_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

class _RecordingScheduler implements AlarmScheduler {
  final scheduled = <String>[];
  final cancelled = <String>[];

  @override
  Future<void> schedule(Alarm alarm) async => scheduled.add(alarm.id);

  @override
  Future<void> cancel(String alarmId) async => cancelled.add(alarmId);
}

void main() {
  group('validateAlarm', () {
    String? check({
      int hour = 7,
      int minute = 0,
      int snooze = 5,
      int? limit,
    }) =>
        validateAlarm(
          hour: hour,
          minute: minute,
          snoozeMinutes: snooze,
          snoozeLimit: limit,
        );

    test('valid values pass, including an empty limit', () {
      expect(check(), isNull);
      expect(check(hour: 23, minute: 59, snooze: 120, limit: 20), isNull);
    });

    test('hour 24 and minute 60 are rejected', () {
      expect(check(hour: 24), isNotNull);
      expect(check(minute: 60), isNotNull);
    });

    test('snooze limit 0 and 21 are rejected', () {
      expect(check(limit: 0), isNotNull);
      expect(check(limit: 21), isNotNull);
      expect(check(limit: 1), isNull);
    });

    test('snooze length outside 1 to 120 is rejected', () {
      expect(check(snooze: 0), isNotNull);
      expect(check(snooze: 121), isNotNull);
    });
  });

  group('timeUntilLabel', () {
    test('formats hours and minutes', () {
      expect(timeUntilLabel(const Duration(hours: 7, minutes: 12)),
          'in 7 h 12 min');
      expect(timeUntilLabel(const Duration(minutes: 45)), 'in 45 min');
      expect(timeUntilLabel(const Duration(seconds: 20)), 'in 1 min');
      expect(timeUntilLabel(Duration.zero), 'in less than a minute');
      expect(timeUntilLabel(const Duration(days: 2, hours: 3)), 'in 2 d 3 h');
    });
  });

  group('AlarmController', () {
    late AppDatabase db;
    late AlarmController controller;
    late _RecordingScheduler scheduler;
    final now = DateTime(2026, 6, 12, 8); // Friday

    setUp(() {
      db = openTestDatabase();
      scheduler = _RecordingScheduler();
      controller = AlarmController(
        AlarmRepository(db, const IdGenerator(), SteppingClock().call),
        scheduler,
        () => now,
      );
    });
    tearDown(() => db.close());

    test('saving schedules the alarm and returns its next trigger', () async {
      final next = await controller.save(
        const AlarmDraft(hour: 7, minute: 0, repeatDays: 0x1F),
      );
      expect(next, DateTime(2026, 6, 15, 7));
      expect(scheduler.scheduled, hasLength(1));
    });

    test('invalid values are rejected before saving', () async {
      await expectLater(
        controller.save(const AlarmDraft(hour: 7, minute: 0, snoozeLimit: 0)),
        throwsA(isA<ValidationException>()),
      );
      expect(await db.select(db.alarms).get(), isEmpty);
    });

    test('switching off cancels; switching on schedules again', () async {
      await controller.save(const AlarmDraft(hour: 6, minute: 30));
      final id = (await db.select(db.alarms).getSingle()).id;

      expect(await controller.setActive(id, false), isNull);
      expect(scheduler.cancelled, [id]);

      expect(await controller.setActive(id, true), DateTime(2026, 6, 13, 6, 30));
      expect(scheduler.scheduled, [id, id]);
    });

    test('update keeps the id and changes the challenge', () async {
      await controller.save(
        const AlarmDraft(hour: 6, minute: 0, challengeType: ChallengeType.maths),
      );
      final id = (await db.select(db.alarms).getSingle()).id;

      await controller.save(
        const AlarmDraft(
          hour: 6,
          minute: 15,
          snoozeLimit: 3,
          challengeType: ChallengeType.phrase,
        ),
        id: id,
      );
      final saved = (await controller.load(id))!;
      expect(saved.alarm.minute, 15);
      expect(saved.alarm.snoozeLimit, 3);
      expect(saved.challenge!.challengeType, ChallengeType.phrase);
    });

    test('delete cancels and removes the alarm', () async {
      await controller.save(const AlarmDraft(hour: 6, minute: 0));
      final id = (await db.select(db.alarms).getSingle()).id;
      await controller.delete(id);
      expect(scheduler.cancelled, contains(id));
      expect(await controller.load(id), isNull);
    });
  });
}
