import 'voice_intent.dart';

/// Turns a recognised English sentence into a [VoiceIntent] without any
/// network access. Matching is rule-based: type keywords, then date and
/// time phrases, and whatever words remain become the title.
class IntentParser {
  const IntentParser();

  VoiceIntent parse(String heard, DateTime now, {VoiceIntentType? forceType}) =>
      _Parse(heard, now, forceType).run();
}

// ---------------------------------------------------------------- patterns

RegExp _re(String pattern) => RegExp(pattern, caseSensitive: false);

const _hourWords = {
  'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6,
  'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11, 'twelve': 12,
};

const _countWords = {
  'a': 1, 'an': 1, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
  'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
};

const _minuteWords = {
  'five': 5, 'ten': 10, 'twenty': 20, 'twenty five': 25, 'twenty-five': 25,
};

const _weekdays = {
  'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4,
  'friday': 5, 'saturday': 6, 'sunday': 7,
};

const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

const _hour = r'(\d{1,2}(?!\d)|(?:one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)\b)';
const _minute = r'(?:[:.h](\d{2}))?';
const _oclock = r"(?:\s*o'?\s?clock)?";
const _meridiem = r'(?:\s*([ap])\.?\s?m\b\.?)?';
const _time = '$_hour$_minute$_oclock$_meridiem';

const _monthName = r'(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|'
    r'july?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|'
    r'dec(?:ember)?)';
const _datePrefix = r'(?:(?:on|for|by|from)\s+)?';

final _fillers = _re(r'\b(?:u+h*m+|u+h+|e+r+m+|a+h+)\b');

final _alarmWords = _re(r'\b(?:wake me|wake up|alarm)\b');
final _eventWords = _re(r'\b(?:meeting|appointment|event|interview|'
    r'lecture|class|party|dinner with|lunch with|call with)\b');
final _reminderStart = _re(r"^(?:(?:can|could|would) you\s+)?(?:please\s+)?"
    r"(?:remind me|don'?t forget|remember to)\b");
final _taskStart = _re(r"^(?:(?:can|could|would) you\s+)?(?:please\s+)?"
    r"(?:add|to-?do|task|i need to|i have to|i must|create a task)\b");

final _range = _re(
    '\\b(?:(from|between)\\s+)?$_time\\s*(?:-|–|\\bto\\b|\\buntil\\b|\\btill\\b|\\band\\b)\\s*$_time');
final _named = _re(r'\b(?:at\s+)?(noon|midday|midnight)\b');
final _pastTo = _re('\\b(?:at\\s+)?(half|quarter|\\d{1,2}|twenty[ -]five|twenty|ten|five)'
    '(?:\\s+minutes?)?\\s+(past|after|to)\\s+$_hour$_meridiem');
final _at = _re('\\bat\\s+$_time');
final _bare = _re('\\b$_time');

final _dayPart = _re(r'\b(?:(?:in the|this)\s+)?(morning|afternoon|evening)\b|'
    r'\b(?:at\s+)?(night)\b|\b(tonight)\b');

final _dayAfterTomorrow = _re('\\b$_datePrefix(?:the\\s+)?day after tomorrow\\b');
final _tomorrow = _re('\\b$_datePrefix(tomorrow)\\b');
final _today = _re('\\b$_datePrefix(today)\\b');
final _inDays = _re(r'\bin\s+(\d{1,2}|an?|one|two|three|four|five|six|seven|'
    r'eight|nine|ten)\s+(days?|weeks?)\b');
final _nextWeek = _re('\\b$_datePrefix(?:next week)\\b');
final _weekday = _re('\\b$_datePrefix(?:(this|next|coming)\\s+)?'
    r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday)s?\b');
final _dayMonth = _re('\\b$_datePrefix(?:the\\s+)?(\\d{1,2})(?:st|nd|rd|th)?'
    '(?:\\s+of)?\\s+$_monthName\\b');
final _monthDay = _re('\\b$_datePrefix$_monthName\\s+(?:the\\s+)?'
    r'(\d{1,2})(?:st|nd|rd|th)?\b');

final _taskPrefix = _re(r"^(?:(?:can|could|would) you\s+)?(?:please\s+)?"
    r"(?:remind me(?:\s+(?:to|about|that))?|add(?:\s+an?)?(?:\s+(?:task|to-?do))?(?:\s+to)?|"
    r"to-?do:?|task:?|i need to|i have to|i must|don'?t forget to|"
    r"remember to|create a task(?:\s+to)?)\s*");
final _taskSuffix = _re(r'\s+(?:to|on)\s+(?:my|the)\s+(?:list|to-?do list|tasks|to-?dos)$');
final _alarmPhrase = _re(r'^(?:(?:can|could|would) you\s+)?(?:please\s+)?'
    r'(?:set|create|add|make)?\s*(?:an?|the|my)?\s*(?:alarm|wake me(?:\s+up)?|wake up)'
    r'(?:\s+(?:for|to|called|named|labell?ed))?\s*');
final _alarmLabel = _re(r'^(?:called|named|labell?ed|for|to)\s+');
final _eventPrefix = _re(r'^(?:(?:can|could|would) you\s+)?(?:please\s+)?'
    r'(?:(?:add|create|schedule|book|put in|set up)\s+(?:an?\s+)?(?:event\s+)?'
    r'(?:for\s+|called\s+)?|i have\s+(?:an?\s+)?|event:?\s+)');

final _leading = _re(r'^(?:to|at|on|for|by|and|then|from)\s+');
final _trailing = _re(r'\s+(?:at|on|for|by|and|from|to|this|next|in|in the)$');

// ------------------------------------------------------------------ parse

enum _DayPart { morning, afternoon }

class _RawTime {
  const _RawTime(this.hour, this.minute, this.meridiem);

  final int hour;
  final int minute;

  /// 'a', 'p' or null when not said.
  final String? meridiem;
}

class _Parse {
  _Parse(String heard, this.now, this.forceType)
      : heard = heard.trim().replaceAll(RegExp(r'\s+'), ' '),
        today = DateTime(now.year, now.month, now.day);

  final String heard;
  final DateTime now;
  final DateTime today;
  final VoiceIntentType? forceType;

  late String rest;
  DateTime? date;
  _RawTime? start;
  _RawTime? end;
  _DayPart? dayPart;

  VoiceIntent run() {
    rest = heard
        .replaceAll(RegExp(r'[,;!?]'), ' ')
        .replaceAll(RegExp(r'\.(?=\s|$)'), ' ')
        .replaceAll(_fillers, ' ');
    rest = _squash(rest);

    final mentionsAlarm = _alarmWords.hasMatch(rest);
    final startsAsReminder = _reminderStart.hasMatch(rest);
    final startsAsTask = _taskStart.hasMatch(rest);
    final mentionsEvent = _eventWords.hasMatch(rest);

    _takeDayPart();
    _takeDate();
    _takeTime();

    final type = forceType ??
        (mentionsAlarm
            ? VoiceIntentType.alarm
            : startsAsReminder
                ? VoiceIntentType.task
                : end != null
                    ? VoiceIntentType.event
                    : mentionsEvent
                        ? VoiceIntentType.event
                        : startsAsTask
                            ? VoiceIntentType.task
                            : VoiceIntentType.unknown);

    final (startTime, endTime) = _resolveTimes(type);

    return VoiceIntent(
      heard: heard,
      type: type,
      title: _title(type),
      date: date,
      time: startTime,
      endTime: type == VoiceIntentType.event ? endTime : null,
    );
  }

  // ------------------------------------------------------------ helpers

  static String _squash(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();

  void _remove(Match match) {
    rest = _squash(rest.replaceRange(match.start, match.end, ' '));
  }

  static int? _hourValue(String? token) {
    if (token == null) return null;
    final value = int.tryParse(token) ?? _hourWords[token.toLowerCase()];
    return value;
  }

  static _RawTime? _timeFrom(String? hourText, String? minuteText, String? meridiem) {
    final hour = _hourValue(hourText);
    final minute = minuteText == null ? 0 : int.tryParse(minuteText);
    if (hour == null || minute == null) return null;
    if (minute > 59) return null;
    final mer = meridiem?.toLowerCase();
    if (mer != null && (hour < 1 || hour > 12)) return null;
    if (hour > 23) return null;
    return _RawTime(hour, minute, mer);
  }

  // ------------------------------------------------------------ day part

  void _takeDayPart() {
    final match = _dayPart.firstMatch(rest);
    if (match == null) return;
    final word = (match.group(1) ?? match.group(2) ?? match.group(3))!.toLowerCase();
    dayPart = word == 'morning' ? _DayPart.morning : _DayPart.afternoon;
    if (word == 'tonight') date ??= today;
    _remove(match);
  }

  // ---------------------------------------------------------------- date

  DateTime _plusDays(int days) =>
      DateTime(today.year, today.month, today.day + days);

  void _takeDate() {
    Match? match;

    if ((match = _dayAfterTomorrow.firstMatch(rest)) != null) {
      date = _plusDays(2);
      _remove(match!);
      return;
    }
    if ((match = _tomorrow.firstMatch(rest)) != null) {
      date = _plusDays(1);
      _remove(match!);
      return;
    }
    if ((match = _today.firstMatch(rest)) != null) {
      date = today;
      _remove(match!);
      return;
    }
    if ((match = _inDays.firstMatch(rest)) != null) {
      final countText = match!.group(1)!.toLowerCase();
      final count = int.tryParse(countText) ?? _countWords[countText] ?? 1;
      final weeks = match.group(2)!.toLowerCase().startsWith('week');
      date = _plusDays(weeks ? count * 7 : count);
      _remove(match);
      return;
    }
    if ((match = _nextWeek.firstMatch(rest)) != null) {
      date = _plusDays(8 - today.weekday);
      _remove(match!);
      return;
    }
    if ((match = _weekday.firstMatch(rest)) != null) {
      final modifier = match!.group(1)?.toLowerCase();
      final target = _weekdays[match.group(2)!.toLowerCase()]!;
      var diff = (target - today.weekday) % 7;
      if (diff == 0 && modifier != 'this') diff = 7;
      // "Next Friday" means the Friday of next week when this week's
      // Friday is still ahead.
      if (modifier == 'next' && today.weekday + diff <= 7) diff += 7;
      date = _plusDays(diff);
      _remove(match);
      return;
    }
    if ((match = _dayMonth.firstMatch(rest)) != null) {
      final parsed = _calendarDate(
          int.parse(match!.group(1)!), match.group(2)!);
      if (parsed != null) {
        date = parsed;
        _remove(match);
        return;
      }
    }
    if ((match = _monthDay.firstMatch(rest)) != null) {
      final parsed = _calendarDate(
          int.parse(match!.group(2)!), match.group(1)!);
      if (parsed != null) {
        date = parsed;
        _remove(match);
      }
    }
  }

  /// The next date with this day and month, today included.
  DateTime? _calendarDate(int day, String monthText) {
    final month = _months[monthText.toLowerCase().substring(0, 3)];
    if (month == null || day < 1 || day > 31) return null;
    var candidate = DateTime(today.year, month, day);
    if (candidate.month != month) return null;
    if (candidate.isBefore(today)) {
      candidate = DateTime(today.year + 1, month, day);
    }
    return candidate;
  }

  // ---------------------------------------------------------------- time

  void _takeTime() {
    final range = _range.firstMatch(rest);
    if (range != null) {
      final keyword = range.group(1)?.toLowerCase();
      final joiner = rest.substring(range.start, range.end).toLowerCase();
      final a = _timeFrom(range.group(2), range.group(3), range.group(4));
      final b = _timeFrom(range.group(5), range.group(6), range.group(7));
      final usesAnd = RegExp(r'\band\b').hasMatch(joiner);
      final clearlyTimes = keyword != null ||
          a?.meridiem != null ||
          b?.meridiem != null ||
          range.group(3) != null ||
          range.group(6) != null;
      if (a != null &&
          b != null &&
          clearlyTimes &&
          (!usesAnd || keyword == 'between')) {
        start = a;
        end = b;
        _remove(range);
        return;
      }
    }

    final named = _named.firstMatch(rest);
    if (named != null) {
      final word = named.group(1)!.toLowerCase();
      start = word == 'midnight' ? const _RawTime(0, 0, null) : const _RawTime(12, 0, 'p');
      _remove(named);
      return;
    }

    final pastTo = _pastTo.firstMatch(rest);
    if (pastTo != null) {
      final amountText = pastTo.group(1)!.toLowerCase();
      final amount = switch (amountText) {
        'half' => 30,
        'quarter' => 15,
        _ => int.tryParse(amountText) ?? _minuteWords[amountText],
      };
      final base = _timeFrom(pastTo.group(3), null, pastTo.group(4));
      final before = pastTo.group(2)!.toLowerCase() == 'to';
      // "2 to 3" is more likely a count than 2 minutes to 3.
      final ambiguous = before &&
          int.tryParse(amountText) != null &&
          !pastTo.group(0)!.toLowerCase().contains('minute');
      if (amount != null && amount < 60 && base != null && !ambiguous) {
        var hour = base.hour;
        var minute = amount;
        if (before) {
          hour = hour - 1;
          minute = 60 - amount;
          if (hour < 1) hour = 12;
        }
        start = _RawTime(hour, minute, base.meridiem);
        _remove(pastTo);
        return;
      }
    }

    final at = _at.firstMatch(rest);
    if (at != null) {
      final parsed = _timeFrom(at.group(1), at.group(2), at.group(3));
      if (parsed != null) {
        start = parsed;
        _remove(at);
        return;
      }
    }

    // Without "at", only clear times count, so "buy 2 apples" keeps its 2.
    for (final bare in _bare.allMatches(rest)) {
      final hasMinutes = bare.group(2) != null;
      final hasMeridiem = bare.group(3) != null;
      final text = rest.substring(bare.start, bare.end).toLowerCase();
      final hasOclock = text.contains('clock');
      if (!hasMinutes && !hasMeridiem && !hasOclock) continue;
      final parsed = _timeFrom(bare.group(1), bare.group(2), bare.group(3));
      if (parsed == null) continue;
      start = parsed;
      _remove(bare);
      return;
    }
  }

  int _resolveHour(_RawTime time, VoiceIntentType type) {
    var hour = time.hour;
    switch (time.meridiem) {
      case 'p':
        return hour == 12 ? 12 : hour + 12;
      case 'a':
        return hour == 12 ? 0 : hour;
    }
    if (hour == 0 || hour >= 13) return hour;
    if (dayPart == _DayPart.afternoon) return hour == 12 ? 12 : hour + 12;
    if (dayPart == _DayPart.morning) return hour == 12 ? 0 : hour;
    // Early hours are rarely meant for tasks and events.
    if (type != VoiceIntentType.alarm && hour >= 1 && hour <= 6) {
      hour += 12;
    }
    return hour;
  }

  (ClockTime?, ClockTime?) _resolveTimes(VoiceIntentType type) {
    final a = start;
    if (a == null) return (null, null);
    final b = end;
    if (b == null) {
      return (ClockTime(_resolveHour(a, type), a.minute), null);
    }

    // "2 to 3 pm": the end's am or pm applies to the start as well.
    var first = a;
    if (a.meridiem == null && b.meridiem != null && a.hour <= 12) {
      first = _RawTime(a.hour, a.minute, b.meridiem);
    }
    var startMinutes = _resolveHour(first, type) * 60 + first.minute;
    var endMinutes = _resolveHour(b, type) * 60 + b.minute;
    if (startMinutes >= endMinutes && first.meridiem == 'p' && a.meridiem == null) {
      // "11 to 1 pm" starts in the morning.
      startMinutes -= 12 * 60;
    }
    if (endMinutes <= startMinutes && b.meridiem == null && endMinutes + 720 < 1440) {
      endMinutes += 12 * 60;
    }
    if (endMinutes <= startMinutes) {
      return (ClockTime.fromMinutes(startMinutes), null);
    }
    return (ClockTime.fromMinutes(startMinutes), ClockTime.fromMinutes(endMinutes));
  }

  // --------------------------------------------------------------- title

  String _title(VoiceIntentType type) {
    var text = rest;
    switch (type) {
      case VoiceIntentType.task:
        text = text.replaceFirst(_taskPrefix, '').replaceFirst(_taskSuffix, '');
      case VoiceIntentType.alarm:
        text = text.replaceFirst(_alarmPhrase, '');
        text = text.replaceAll(_re(r'\b(?:set\s+)?(?:an?\s+)?alarm\b'), ' ');
        text = _squash(text).replaceFirst(_alarmLabel, '');
      case VoiceIntentType.event:
        text = text.replaceFirst(_eventPrefix, '');
      case VoiceIntentType.unknown:
        break;
    }
    text = _squash(text);
    var changed = true;
    while (changed && text.isNotEmpty) {
      final before = text;
      text = text.replaceFirst(_leading, '').replaceFirst(_trailing, '').trim();
      changed = text != before;
    }
    text = text.replaceAll(RegExp(r'^[\s:\-–.]+|[\s:\-–.]+$'), '');
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}
