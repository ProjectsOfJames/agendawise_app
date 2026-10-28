import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/core/domain/task_priority.dart';
import 'package:agendawise/features/alarms/domain/alarm_days.dart';
import 'package:agendawise/features/calendar/domain/calendar_agenda.dart';
import 'package:agendawise/features/calendar/domain/repeat_rule.dart';
import 'package:flutter_test/flutter_test.dart';

final _created = DateTime(2026, 1, 1);

CalendarEvent _event(
  String id, {
  required DateTime start,
  DateTime? end,
  bool allDay = false,
  bool isAuto = false,
  String? repeat,
}) =>
    CalendarEvent(
      id: id,
      title: id,
      startAt: start,
      endAt: end ?? start.add(const Duration(hours: 1)),
      isAllDay: allDay,
      colour: '#8B5CF6',
      isAuto: isAuto,
      repeatRule: repeat,
      createdAt: _created,
    );

Task _task(String id, DateTime? due, {bool allDay = false}) => Task(
      id: id,
      title: id,
      priority: TaskPriority.medium,
      dueAt: due,
      isAllDay: allDay,
      isDone: false,
      createdAt: _created,
    );

Alarm _alarm(
  String id, {
  int hour = 7,
  int minute = 0,
  int repeatDays = 0,
  bool active = true,
}) =>
    Alarm(
      id: id,
      title: id,
      hour: hour,
      minute: minute,
      repeatDays: repeatDays,
      snoozeMinutes: 5,
      soundRef: 'tone_1',
      vibrate: true,
      isActive: active,
      createdAt: _created,
      updatedAt: _created,
    );

void main() {
  group('RepeatRule', () {
    test('round-trips through RRULE text', () {
      const rule = RepeatRule(RepeatUnit.weeks, 2);
      expect(rule.toRrule(), 'FREQ=WEEKLY;INTERVAL=2');
      expect(RepeatRule.tryParse('FREQ=WEEKLY;INTERVAL=2'), rule);
      expect(RepeatRule.tryParse('freq=daily'), const RepeatRule(RepeatUnit.days));
      expect(RepeatRule.tryParse(null), isNull);
      expect(RepeatRule.tryParse('nonsense'), isNull);
    });

    final start = DateTime(2026, 6, 15, 9); // Monday

    test('every 2 days', () {
      const rule = RepeatRule(RepeatUnit.days, 2);
      expect(rule.occursOn(start, DateTime(2026, 6, 15)), isTrue);
      expect(rule.occursOn(start, DateTime(2026, 6, 16)), isFalse);
      expect(rule.occursOn(start, DateTime(2026, 6, 17)), isTrue);
      expect(rule.occursOn(start, DateTime(2026, 6, 13)), isFalse);
    });

    test('every 2 weeks', () {
      const rule = RepeatRule(RepeatUnit.weeks, 2);
      expect(rule.occursOn(start, DateTime(2026, 6, 22)), isFalse);
      expect(rule.occursOn(start, DateTime(2026, 6, 29)), isTrue);
    });

    test('monthly skips months without the day', () {
      const rule = RepeatRule(RepeatUnit.months);
      final jan31 = DateTime(2026, 1, 31);
      expect(rule.occursOn(jan31, DateTime(2026, 2, 28)), isFalse);
      expect(rule.occursOn(jan31, DateTime(2026, 3, 31)), isTrue);
    });

    test('yearly', () {
      const rule = RepeatRule(RepeatUnit.years);
      expect(rule.occursOn(start, DateTime(2027, 6, 15)), isTrue);
      expect(rule.occursOn(start, DateTime(2027, 6, 16)), isFalse);
    });
  });

  group('alarm days', () {
    final now = DateTime(2026, 6, 12, 8); // Friday 08:00

    test('weekday alarm asked on Friday after it rang gives Monday', () {
      const weekdays = 0x1F; // Monday to Friday
      final next = nextAlarmTrigger(_alarm('a', repeatDays: weekdays), now);
      expect(next, DateTime(2026, 6, 15, 7));
    });

    test('one-off alarm already passed today rings tomorrow', () {
      final next = nextAlarmTrigger(_alarm('a'), now);
      expect(next, DateTime(2026, 6, 13, 7));
      expect(alarmRingsOn(_alarm('a'), DateTime(2026, 6, 13), now), isTrue);
      expect(alarmRingsOn(_alarm('a'), DateTime(2026, 6, 14), now), isFalse);
    });

    test('inactive alarms never ring', () {
      expect(nextAlarmTrigger(_alarm('a', active: false), now), isNull);
    });

    test('repeating alarm shows on its weekdays from today on', () {
      final mondays = _alarm('a', repeatDays: weekdayBit(DateTime.monday));
      expect(alarmRingsOn(mondays, DateTime(2026, 6, 15), now), isTrue);
      expect(alarmRingsOn(mondays, DateTime(2026, 6, 16), now), isFalse);
      expect(alarmRingsOn(mondays, DateTime(2026, 6, 8), now), isFalse);
    });
  });

  group('CalendarAgenda', () {
    final month = DateTime(2026, 6);
    final now = DateTime(2026, 6, 1, 6);

    test('collects events, tasks and alarms per day in time order', () {
      final agenda = CalendarAgenda.build(
        month: month,
        events: [_event('Design review', start: DateTime(2026, 6, 15, 14))],
        tasks: [_task('Report', DateTime(2026, 6, 15, 9))],
        alarms: [_alarm('Gym', hour: 6, repeatDays: weekdayBit(DateTime.monday))],
        now: now,
      );
      final items = agenda.itemsOn(DateTime(2026, 6, 15));
      expect(items.map((i) => i.title), ['Gym', 'Report', 'Design review']);
      expect(agenda.hasItemsOn(DateTime(2026, 6, 16)), isFalse);
    });

    test('automatic events are hidden; their task is shown', () {
      final due = DateTime(2026, 6, 18, 9);
      final agenda = CalendarAgenda.build(
        month: month,
        events: [_event('Report event', start: due, isAuto: true)],
        tasks: [_task('Report', due)],
        alarms: const [],
        now: now,
      );
      final items = agenda.itemsOn(DateTime(2026, 6, 18));
      expect(items, hasLength(1));
      expect(items.single.kind, AgendaKind.task);
    });

    test('repeating and multi-day events appear on each day', () {
      final agenda = CalendarAgenda.build(
        month: month,
        events: [
          _event('Standup',
              start: DateTime(2026, 5, 4, 9), repeat: 'FREQ=WEEKLY;INTERVAL=1'),
          _event('Trip',
              start: DateTime(2026, 6, 20),
              end: DateTime(2026, 6, 22, 23, 59),
              allDay: true),
        ],
        tasks: const [],
        alarms: const [],
        now: now,
      );
      final mondays = [1, 8, 15, 22, 29];
      for (final d in mondays) {
        final standup = agenda
            .itemsOn(DateTime(2026, 6, d))
            .where((i) => i.title == 'Standup');
        expect(standup.single.time, DateTime(2026, 6, d, 9));
      }
      // 22 June is also a Monday, so only the trip is checked here.
      for (final d in [20, 21, 22]) {
        final trip = agenda
            .itemsOn(DateTime(2026, 6, d))
            .where((i) => i.title == 'Trip');
        expect(trip.single.allDay, isTrue);
      }
      expect(agenda.hasItemsOn(DateTime(2026, 6, 23)), isFalse);
    });

    test('all-day items come first and undated tasks are ignored', () {
      final agenda = CalendarAgenda.build(
        month: month,
        events: [_event('Lunch', start: DateTime(2026, 6, 10, 12))],
        tasks: [
          _task('Pay rent', DateTime(2026, 6, 10), allDay: true),
          _task('Someday', null),
        ],
        alarms: const [],
        now: now,
      );
      expect(agenda.itemsOn(DateTime(2026, 6, 10)).map((i) => i.title),
          ['Pay rent', 'Lunch']);
    });
  });
}
