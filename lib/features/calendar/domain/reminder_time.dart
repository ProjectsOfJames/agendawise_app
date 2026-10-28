import '../../../core/database/app_database.dart';
import '../../../core/utils/date_labels.dart';
import 'repeat_rule.dart';

/// Next time the reminder for [event] should fire after [now], or null if
/// it has none or every occurrence has passed. Repeating events are searched
/// day by day up to [searchDays] ahead.
DateTime? nextReminderTime(
  CalendarEvent event,
  DateTime now, {
  int searchDays = 3700,
}) {
  final before = event.reminderMinutesBefore;
  if (before == null) return null;
  final offset = Duration(minutes: before);

  final rule = RepeatRule.tryParse(event.repeatRule);
  if (rule == null) {
    final at = event.startAt.subtract(offset);
    return at.isAfter(now) ? at : null;
  }

  // Start from the first day whose reminder could still be ahead.
  var day = dateOnly(now.add(offset));
  final first = dateOnly(event.startAt);
  if (day.isBefore(first)) day = first;
  for (var i = 0; i < searchDays; i++) {
    final candidate = DateTime(day.year, day.month, day.day + i);
    if (!rule.occursOn(event.startAt, candidate)) continue;
    final start = DateTime(candidate.year, candidate.month, candidate.day,
        event.startAt.hour, event.startAt.minute);
    final at = start.subtract(offset);
    if (at.isAfter(now)) return at;
  }
  return null;
}
