import '../../../core/database/app_database.dart';
import '../../../core/utils/date_labels.dart';

/// Bit for a weekday in the repeat mask: Monday is bit 0, Sunday bit 6.
int weekdayBit(int weekday) => 1 << (weekday - 1);

bool repeatsOnWeekday(int repeatDays, int weekday) =>
    repeatDays & weekdayBit(weekday) != 0;

/// Next time the alarm rings strictly after [now], or null if inactive.
DateTime? nextAlarmTrigger(Alarm alarm, DateTime now) {
  if (!alarm.isActive) return null;
  final ringOn = alarm.ringOn;
  if (alarm.repeatDays == 0 && ringOn != null) {
    final at = DateTime(
        ringOn.year, ringOn.month, ringOn.day, alarm.hour, alarm.minute);
    return at.isAfter(now) ? at : null;
  }
  for (var offset = 0; offset <= 7; offset++) {
    final day = dateOnly(now).add(Duration(days: offset));
    final candidate =
        DateTime(day.year, day.month, day.day, alarm.hour, alarm.minute);
    if (!candidate.isAfter(now)) continue;
    if (alarm.repeatDays == 0 || repeatsOnWeekday(alarm.repeatDays, day.weekday)) {
      return candidate;
    }
  }
  return null;
}

/// Whether an active alarm rings on [day]. Repeating alarms ring on their
/// weekdays from today on; a one-off alarm rings only on its next trigger
/// day (its fixed date, when it has one).
bool alarmRingsOn(Alarm alarm, DateTime day, DateTime now) {
  if (!alarm.isActive) return false;
  final target = dateOnly(day);
  if (alarm.repeatDays != 0) {
    return !target.isBefore(dateOnly(now)) &&
        repeatsOnWeekday(alarm.repeatDays, target.weekday);
  }
  final next = nextAlarmTrigger(alarm, now);
  return next != null && dateOnly(next) == target;
}
