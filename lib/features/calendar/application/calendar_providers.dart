import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/date_labels.dart';
import '../../alarms/data/alarm_repository.dart';
import '../../tasks/data/task_repository.dart';
import '../data/event_repository.dart';
import '../domain/calendar_agenda.dart';

class SelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(ref.watch(clockProvider)());

  void select(DateTime day) => state = dateOnly(day);
}

/// The day highlighted on the calendar; its month is the month shown.
final selectedDayProvider =
    NotifierProvider<SelectedDayNotifier, DateTime>(SelectedDayNotifier.new);

/// First day of the month containing the selected day.
final shownMonthProvider = Provider<DateTime>((ref) {
  final day = ref.watch(selectedDayProvider);
  return DateTime(day.year, day.month);
});

DateTime _monthEnd(DateTime month) => DateTime(month.year, month.month + 1);

final _monthEventsProvider =
    StreamProvider.family<List<CalendarEvent>, DateTime>((ref, month) {
  return ref.watch(eventRepositoryProvider).watchOverlapping(month, _monthEnd(month));
});

final _repeatingEventsProvider = StreamProvider<List<CalendarEvent>>(
  (ref) => ref.watch(eventRepositoryProvider).watchRepeating(),
);

final _monthTasksProvider =
    StreamProvider.family<List<Task>, DateTime>((ref, month) {
  return ref.watch(taskRepositoryProvider).watchDueBetween(month, _monthEnd(month));
});

final _alarmsProvider = StreamProvider<List<Alarm>>((ref) => ref
    .watch(alarmRepositoryProvider)
    .watchAll()
    .map((rows) => [for (final row in rows) row.alarm]));

/// Everything shown on the calendar for [month] (its first day).
final monthAgendaProvider =
    Provider.family<AsyncValue<CalendarAgenda>, DateTime>((ref, month) {
  final events = ref.watch(_monthEventsProvider(month));
  final repeating = ref.watch(_repeatingEventsProvider);
  final tasks = ref.watch(_monthTasksProvider(month));
  final alarms = ref.watch(_alarmsProvider);

  final parts = [events, repeating, tasks, alarms];
  for (final part in parts) {
    if (part.hasError) return AsyncValue.error(part.error!, part.stackTrace!);
  }
  if (parts.any((part) => !part.hasValue)) return const AsyncValue.loading();

  final byId = <String, CalendarEvent>{
    for (final event in events.requireValue) event.id: event,
    for (final event in repeating.requireValue) event.id: event,
  };
  return AsyncValue.data(
    CalendarAgenda.build(
      month: month,
      events: byId.values.toList(),
      tasks: tasks.requireValue,
      alarms: alarms.requireValue,
      now: ref.watch(clockProvider)(),
    ),
  );
});
