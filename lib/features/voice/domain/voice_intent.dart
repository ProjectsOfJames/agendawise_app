enum VoiceIntentType {
  task('Task'),
  alarm('Alarm'),
  event('Event'),
  unknown('Unknown');

  const VoiceIntentType(this.label);

  final String label;
}

/// A time of day without a date.
class ClockTime {
  const ClockTime(this.hour, this.minute)
      : assert(hour >= 0 && hour < 24),
        assert(minute >= 0 && minute < 60);

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  static ClockTime fromMinutes(int minutes) {
    const last = 24 * 60 - 1;
    final clamped = minutes < 0 ? 0 : (minutes > last ? last : minutes);
    return ClockTime(clamped ~/ 60, clamped % 60);
  }

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// What a spoken sentence asks for. Every field can still be changed on the
/// confirmation screen before anything is saved.
class VoiceIntent {
  const VoiceIntent({
    required this.heard,
    required this.type,
    this.title = '',
    this.date,
    this.time,
    this.endTime,
  });

  /// The words as recognised.
  final String heard;
  final VoiceIntentType type;
  final String title;

  /// Local midnight of the day mentioned, or null when no day was said.
  final DateTime? date;
  final ClockTime? time;

  /// End of a time range ("from 2 to 3 pm"); events only.
  final ClockTime? endTime;

  /// False when the sentence should go to the fallback screen instead of
  /// the confirmation screen.
  bool get isUnderstood => switch (type) {
        VoiceIntentType.unknown => false,
        VoiceIntentType.alarm => time != null,
        VoiceIntentType.task || VoiceIntentType.event => title.isNotEmpty,
      };

  VoiceIntent copyWith({
    VoiceIntentType? type,
    String? title,
    DateTime? date,
    bool clearDate = false,
    ClockTime? time,
    bool clearTime = false,
    ClockTime? endTime,
    bool clearEndTime = false,
  }) =>
      VoiceIntent(
        heard: heard,
        type: type ?? this.type,
        title: title ?? this.title,
        date: clearDate ? null : (date ?? this.date),
        time: clearTime ? null : (time ?? this.time),
        endTime: clearEndTime ? null : (endTime ?? this.endTime),
      );

  @override
  String toString() =>
      'VoiceIntent($type, "$title", date: $date, time: $time, end: $endTime)';
}
