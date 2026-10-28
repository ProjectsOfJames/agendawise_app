import '../../../core/utils/date_labels.dart';

enum RepeatUnit {
  days('DAILY'),
  weeks('WEEKLY'),
  months('MONTHLY'),
  years('YEARLY');

  const RepeatUnit(this.frequency);

  /// iCalendar FREQ value.
  final String frequency;
}

/// A simple repeat: every [interval] [unit]s from the event's start date.
/// Stored as an iCalendar RRULE subset, e.g. "FREQ=WEEKLY;INTERVAL=2".
class RepeatRule {
  const RepeatRule(this.unit, [this.interval = 1])
      : assert(interval >= 1, 'interval must be at least 1');

  final RepeatUnit unit;
  final int interval;

  String toRrule() => 'FREQ=${unit.frequency};INTERVAL=$interval';

  /// Returns null for empty or unrecognised text.
  static RepeatRule? tryParse(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    RepeatUnit? unit;
    var interval = 1;
    for (final part in text.toUpperCase().split(';')) {
      final pieces = part.split('=');
      if (pieces.length != 2) continue;
      final key = pieces[0].trim();
      final value = pieces[1].trim();
      if (key == 'FREQ') {
        for (final candidate in RepeatUnit.values) {
          if (candidate.frequency == value) unit = candidate;
        }
      } else if (key == 'INTERVAL') {
        interval = int.tryParse(value) ?? 1;
      }
    }
    if (unit == null || interval < 1) return null;
    return RepeatRule(unit, interval);
  }

  /// Whether an event first held on [start] has an occurrence on [day].
  /// Monthly and yearly repeats skip months that lack the start's day.
  bool occursOn(DateTime start, DateTime day) {
    final first = dateOnly(start);
    final target = dateOnly(day);
    if (target.isBefore(first)) return false;

    switch (unit) {
      case RepeatUnit.days:
        return _daysBetween(first, target) % interval == 0;
      case RepeatUnit.weeks:
        final days = _daysBetween(first, target);
        return days % 7 == 0 && (days ~/ 7) % interval == 0;
      case RepeatUnit.months:
        final months =
            (target.year - first.year) * 12 + target.month - first.month;
        return target.day == first.day && months % interval == 0;
      case RepeatUnit.years:
        return target.month == first.month &&
            target.day == first.day &&
            (target.year - first.year) % interval == 0;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RepeatRule && other.unit == unit && other.interval == interval;

  @override
  int get hashCode => Object.hash(unit, interval);
}

// UTC dates avoid daylight-saving shifts in day counts.
int _daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;
