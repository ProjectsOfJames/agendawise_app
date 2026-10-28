import '../../../core/domain/challenge_type.dart';

const snoozeLengthPresets = [5, 10, 15, 30];
const minSnoozeMinutes = 1;
const maxSnoozeMinutes = 120;
const minSnoozeLimit = 1;
const maxSnoozeLimit = 20;

/// Bundled alarm tones, keyed by the value stored in alarms.sound_ref.
const alarmTones = {
  'tone_1': 'Rise',
  'tone_2': 'Chime',
  'tone_3': 'Pulse',
};

String challengeName(ChallengeType? type) => switch (type) {
      null => 'Off',
      ChallengeType.maths => 'Maths',
      ChallengeType.memory => 'Memory',
      ChallengeType.phrase => 'Phrase',
      ChallengeType.shake => 'Shake',
    };

/// Returns a message for the first rule the values break, or null if valid.
/// The label is optional and never invalid.
String? validateAlarm({
  required int hour,
  required int minute,
  required int snoozeMinutes,
  required int? snoozeLimit,
}) {
  if (hour < 0 || hour > 23) return 'Hour must be between 0 and 23';
  if (minute < 0 || minute > 59) return 'Minute must be between 0 and 59';
  if (snoozeMinutes < minSnoozeMinutes || snoozeMinutes > maxSnoozeMinutes) {
    return 'Snooze length must be $minSnoozeMinutes to $maxSnoozeMinutes minutes';
  }
  if (snoozeLimit != null &&
      (snoozeLimit < minSnoozeLimit || snoozeLimit > maxSnoozeLimit)) {
    return 'Allowed snoozes must be $minSnoozeLimit to $maxSnoozeLimit';
  }
  return null;
}

/// "in 7 h 12 min", "in 45 min" or "in less than a minute".
String timeUntilLabel(Duration until) {
  final minutes = (until.inSeconds / 60).ceil();
  if (minutes < 1) return 'in less than a minute';
  final days = minutes ~/ 1440;
  final hours = (minutes % 1440) ~/ 60;
  final rest = minutes % 60;
  final parts = [
    if (days > 0) '$days d',
    if (hours > 0) '$hours h',
    if (rest > 0 && days == 0) '$rest min',
  ];
  return 'in ${parts.join(' ')}';
}
