import '../../../core/database/app_database.dart';
import '../../../core/domain/task_priority.dart';
import '../../../core/utils/date_labels.dart';
import '../../alarms/domain/alarm_days.dart';
import 'repeat_rule.dart';

enum AgendaKind { event, task, alarm }

/// One entry in a day's list on the calendar.
class AgendaItem {
  const AgendaItem({
    required this.kind,
    required this.id,
    required this.title,
    this.time,
    this.endTime,
    this.allDay = false,
    this.colourHex,
    this.priority,
    this.isDone = false,
    this.location,
  });

  final AgendaKind kind;
  final String id;
  final String title;

  /// Start time on this day; null for all-day items.
  final DateTime? time;
  final DateTime? endTime;
  final bool allDay;
  final String? colourHex;
  final TaskPriority? priority;
  final bool isDone;
  final String? location;
}

/// Builds the items shown on each day of a month.
///
/// Automatic events are left out because the calendar shows a linked record
/// only through its source task.
class CalendarAgenda {
  CalendarAgenda._(this._days);

  factory CalendarAgenda.build({
    required DateTime month,
    required List<CalendarEvent> events,
    required List<Task> tasks,
    required List<Alarm> alarms,
    required DateTime now,
  }) {
    final first = DateTime(month.year, month.month);
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    final days = <DateTime, List<AgendaItem>>{};

    void add(DateTime day, AgendaItem item) =>
        days.putIfAbsent(dateOnly(day), () => []).add(item);

    for (var i = 0; i < dayCount; i++) {
      final day = DateTime(first.year, first.month, first.day + i);

      for (final event in events) {
        if (event.isAuto) continue;
        final rule = RepeatRule.tryParse(event.repeatRule);
        final DateTime start;
        if (rule != null) {
          if (!rule.occursOn(event.startAt, day)) continue;
          start = _onDay(day, event.startAt);
        } else {
          final startDay = dateOnly(event.startAt);
          final endDay = dateOnly(event.endAt);
          if (day.isBefore(startDay) || day.isAfter(endDay)) continue;
          start = startDay == day ? event.startAt : day;
        }
        final duration = event.endAt.difference(event.startAt);
        add(
          day,
          AgendaItem(
            kind: AgendaKind.event,
            id: event.id,
            title: event.title,
            time: event.isAllDay ? null : start,
            endTime: event.isAllDay ? null : start.add(duration),
            allDay: event.isAllDay,
            colourHex: event.colour,
            location: event.location,
          ),
        );
      }

      for (final task in tasks) {
        final due = task.dueAt;
        if (due == null || dateOnly(due) != day) continue;
        add(
          day,
          AgendaItem(
            kind: AgendaKind.task,
            id: task.id,
            title: task.title,
            time: task.isAllDay ? null : due,
            allDay: task.isAllDay,
            priority: task.priority,
            isDone: task.isDone,
          ),
        );
      }

      for (final alarm in alarms) {
        if (!alarmRingsOn(alarm, day, now)) continue;
        add(
          day,
          AgendaItem(
            kind: AgendaKind.alarm,
            id: alarm.id,
            title: alarm.title ?? 'Alarm',
            time: DateTime(day.year, day.month, day.day, alarm.hour, alarm.minute),
          ),
        );
      }
    }

    for (final items in days.values) {
      items.sort(_compare);
    }
    return CalendarAgenda._(days);
  }

  final Map<DateTime, List<AgendaItem>> _days;

  List<AgendaItem> itemsOn(DateTime day) => _days[dateOnly(day)] ?? const [];

  bool hasItemsOn(DateTime day) => _days.containsKey(dateOnly(day));
}

DateTime _onDay(DateTime day, DateTime time) => DateTime(
    day.year, day.month, day.day, time.hour, time.minute, time.second);

// All-day items first, then by time, then events before tasks before alarms.
int _compare(AgendaItem a, AgendaItem b) {
  if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
  final at = a.time, bt = b.time;
  if (at != null && bt != null) {
    final byTime = at.compareTo(bt);
    if (byTime != 0) return byTime;
  }
  final byKind = a.kind.index.compareTo(b.kind.index);
  return byKind != 0 ? byKind : a.title.compareTo(b.title);
}
