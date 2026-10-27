const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String twoDigits(int value) => value.toString().padLeft(2, '0');

/// 24-hour time, e.g. "09:05".
String timeLabel(DateTime value) =>
    '${twoDigits(value.hour)}:${twoDigits(value.minute)}';

/// "Today", "Tomorrow", "Yesterday", or e.g. "Mon 2 Nov" (year added when
/// it differs from [now]).
String dayLabel(DateTime value, DateTime now) {
  final difference = dateOnly(value).difference(dateOnly(now)).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Tomorrow';
  if (difference == -1) return 'Yesterday';
  final base =
      '${_weekdays[value.weekday - 1]} ${value.day} ${_months[value.month - 1]}';
  return value.year == now.year ? base : '$base ${value.year}';
}

/// Due label for a task: the day, plus the time unless it is all-day.
String dueLabel(DateTime dueAt, {required bool allDay, required DateTime now}) {
  final day = dayLabel(dueAt, now);
  return allDay ? day : '$day · ${timeLabel(dueAt)}';
}
