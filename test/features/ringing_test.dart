import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/core/domain/interaction_event_type.dart';
import 'package:agendawise/core/utils/id_generator.dart';
import 'package:agendawise/features/alarms/application/alarm_scheduler.dart';
import 'package:agendawise/features/alarms/application/ringing_controller.dart';
import 'package:agendawise/features/alarms/data/alarm_repository.dart';
import 'package:agendawise/features/alarms/data/alarm_sound_store.dart';
import 'package:agendawise/features/alarms/domain/alarm_ids.dart';
import 'package:agendawise/features/alarms/domain/alarm_rules.dart';
import 'package:agendawise/features/calendar/domain/reminder_time.dart';
import 'package:agendawise/features/difficulty/data/interaction_log_repository.dart';
import 'package:agendawise/features/difficulty/data/interaction_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

class _FakeNative implements AlarmScheduler, AlarmPlayback {
  final calls = <String>[];

  @override
  Future<void> schedule(Alarm alarm) async => calls.add('schedule');

  @override
  Future<void> cancel(String alarmId) async => calls.add('cancel');

  @override
  Future<void> stop(String alarmId) async => calls.add('stop');

  @override
  Future<void> snooze(
    Alarm alarm, {
    required int snoozesUsed,
    required Duration delay,
  }) async =>
      calls.add('snooze $snoozesUsed ${delay.inMinutes}');
}

CalendarEvent _event({
  required DateTime start,
  int? reminder = 10,
  String? repeat,
}) =>
    CalendarEvent(
      id: 'e',
      title: 'Standup',
      startAt: start,
      endAt: start.add(const Duration(hours: 1)),
      isAllDay: false,
      colour: '#8B5CF6',
      reminderMinutesBefore: reminder,
      repeatRule: repeat,
      isAuto: false,
      createdAt: DateTime(2026),
    );

void main() {
  group('snooze rule', () {
    test('limit 3 with 1 used shows Snooze', () {
      expect(canSnooze(limit: 3, used: 1), isTrue);
    });

    test('limit 3 with 3 used hides Snooze', () {
      expect(canSnooze(limit: 3, used: 3), isFalse);
    });

    test('no limit with 50 used still shows Snooze', () {
      expect(canSnooze(limit: null, used: 50), isTrue);
    });
  });

  group('native ids and payload', () {
    test('ids are stable, positive and differ by salt', () {
      final a = nativeIdFor('abc');
      expect(nativeIdFor('abc'), a);
      expect(a, greaterThan(0));
      expect(a, lessThanOrEqualTo(0x7FFFFFFF));
      expect(nativeIdFor('abc', salt: 'reminder'), isNot(a));
      expect(nativeIdFor('abd'), isNot(a));
    });

    test('payload round-trips and rejects junk', () {
      const payload = RingPayload(alarmId: 'x', snoozesUsed: 2);
      final decoded = RingPayload.decode(payload.encode())!;
      expect(decoded.alarmId, 'x');
      expect(decoded.snoozesUsed, 2);
      expect(RingPayload.decode('not json'), isNull);
      expect(RingPayload.decode('{"snoozes": 1}'), isNull);
      expect(RingPayload.decode(null), isNull);
    });
  });

  group('sound refs', () {
    test('tones map to bundled assets and unknown refs fall back', () {
      expect(AlarmSoundStore.audioPathFor('tone_2'), 'assets/sounds/tone_2.wav');
      expect(AlarmSoundStore.audioPathFor('mystery'), 'assets/sounds/tone_1.wav');
      expect(AlarmSoundStore.audioPathFor('file:/missing/file.mp3'),
          'assets/sounds/tone_1.wav');
      expect(AlarmSoundStore.displayName('tone_3'), 'Pulse');
      expect(AlarmSoundStore.displayName('file:/x/sounds/1a2b3c4d_wake.mp3'),
          'wake.mp3');
    });
  });

  group('nextReminderTime', () {
    final now = DateTime(2026, 6, 15, 8);

    test('one-off reminder before the start, or none once passed', () {
      expect(nextReminderTime(_event(start: DateTime(2026, 6, 15, 9)), now),
          DateTime(2026, 6, 15, 8, 50));
      expect(nextReminderTime(_event(start: DateTime(2026, 6, 15, 8, 5)), now),
          isNull);
      expect(
          nextReminderTime(
              _event(start: DateTime(2026, 6, 15, 9), reminder: null), now),
          isNull);
    });

    test('repeating event uses the next occurrence still ahead', () {
      final weekly = _event(
        start: DateTime(2026, 6, 1, 8, 5),
        repeat: 'FREQ=WEEKLY;INTERVAL=1',
      );
      // Today's 07:55 reminder has passed, so next Monday's is used.
      expect(nextReminderTime(weekly, now), DateTime(2026, 6, 22, 7, 55));
    });

    test('a day-before reminder for tomorrow fires today', () {
      final event =
          _event(start: DateTime(2026, 6, 16, 9), reminder: 1440);
      expect(nextReminderTime(event, now), DateTime(2026, 6, 15, 9));
    });
  });

  group('RingingController', () {
    late AppDatabase db;
    late AlarmRepository alarms;
    late _FakeNative native;
    late RingingController controller;
    late InteractionLogRepository logs;

    setUp(() {
      db = openTestDatabase();
      final clock = SteppingClock();
      alarms = AlarmRepository(db, const IdGenerator(), clock.call);
      native = _FakeNative();
      controller = RingingController(
        alarms,
        native,
        native,
        InteractionLogger(db.interactionLogsDao, const IdGenerator(), clock.call),
      );
      logs = InteractionLogRepository(db.interactionLogsDao);
    });
    tearDown(() => db.close());

    Future<Alarm> create(AlarmDraft draft) async =>
        (await alarms.getById(await alarms.create(draft)))!.alarm;

    test('snooze reschedules with the next count and logs', () async {
      final alarm = await create(
          const AlarmDraft(hour: 6, minute: 0, snoozeMinutes: 10, snoozeLimit: 2));
      expect(await controller.snooze(alarm, snoozesUsed: 1), isTrue);
      expect(native.calls, ['snooze 2 10']);
      expect(await logs.count(InteractionEventType.alarmSnoozed), 1);
    });

    test('snooze is refused at the limit', () async {
      final alarm =
          await create(const AlarmDraft(hour: 6, minute: 0, snoozeLimit: 2));
      expect(await controller.snooze(alarm, snoozesUsed: 2), isFalse);
      expect(native.calls, isEmpty);
    });

    test('dismissing a one-off alarm switches it off', () async {
      final alarm = await create(const AlarmDraft(hour: 6, minute: 0));
      await controller.dismiss(alarm);
      expect(native.calls, ['stop']);
      expect((await alarms.getById(alarm.id))!.alarm.isActive, isFalse);
      expect(await logs.count(InteractionEventType.alarmDismissed), 1);
    });

    test('dismissing a repeating alarm schedules its next day', () async {
      final alarm =
          await create(const AlarmDraft(hour: 6, minute: 0, repeatDays: 0x1F));
      await controller.dismiss(alarm);
      expect(native.calls, ['stop', 'schedule']);
      expect((await alarms.getById(alarm.id))!.alarm.isActive, isTrue);
    });
  });
}
