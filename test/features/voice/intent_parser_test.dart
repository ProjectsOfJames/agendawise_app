import 'package:agendawise/features/voice/domain/intent_parser.dart';
import 'package:agendawise/features/voice/domain/voice_intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A Friday.
  final now = DateTime(2026, 10, 30, 10);
  const parser = IntentParser();
  VoiceIntent parse(String text, {VoiceIntentType? as}) =>
      parser.parse(text, now, forceType: as);

  group('design test cases', () {
    test('UT-38 a reminder becomes a task with date and time', () {
      final intent = parse('remind me to submit the report tomorrow at 9');
      expect(intent.type, VoiceIntentType.task);
      expect(intent.title.toLowerCase(), 'submit the report');
      expect(intent.date, DateTime(2026, 10, 31));
      expect(intent.time, const ClockTime(9, 0));
      expect(intent.isUnderstood, isTrue);
    });

    test('UT-39 "wake me" becomes an alarm', () {
      final intent = parse('wake me at 6:30 tomorrow');
      expect(intent.type, VoiceIntentType.alarm);
      expect(intent.time, const ClockTime(6, 30));
      expect(intent.date, DateTime(2026, 10, 31));
      expect(intent.isUnderstood, isTrue);
    });

    test('UT-40 a meeting with a time range becomes an event', () {
      final intent = parse('meeting with Sam on Friday from 2 to 3 pm');
      expect(intent.type, VoiceIntentType.event);
      expect(intent.title, 'Meeting with Sam');
      expect(intent.date, DateTime(2026, 11, 6));
      expect(intent.time, const ClockTime(14, 0));
      expect(intent.endTime, const ClockTime(15, 0));
    });

    test('UT-41 an unclear sentence goes to the fallback screen', () {
      final intent = parse('uhm the thing for friday maybe');
      expect(intent.type, VoiceIntentType.unknown);
      expect(intent.isUnderstood, isFalse);
    });
  });

  group('types and titles', () {
    test('alarm labels', () {
      final intent = parse('Set an alarm for 7 am called gym');
      expect(intent.type, VoiceIntentType.alarm);
      expect(intent.title, 'Gym');
      expect(intent.time, const ClockTime(7, 0));
      expect(intent.date, isNull);
    });

    test('add to my list', () {
      final intent = parse('Add milk to my list');
      expect(intent.type, VoiceIntentType.task);
      expect(intent.title, 'Milk');
      expect(intent.time, isNull);
    });

    test('reminder phrasing wins over a time range', () {
      final intent = parse('remind me to call the bank between 9 and 10');
      expect(intent.type, VoiceIntentType.task);
      expect(intent.title, 'Call the bank');
      expect(intent.time, const ClockTime(9, 0));
      expect(intent.endTime, isNull);
    });

    test('words after the time stay in the title', () {
      final intent = parse('Remind me at 10 to check the oven');
      expect(intent.title, 'Check the oven');
      expect(intent.time, const ClockTime(10, 0));
    });

    test('an event without a time keeps the title', () {
      final intent = parse('Dentist appointment on the 5th of November at half past 10');
      expect(intent.type, VoiceIntentType.event);
      expect(intent.title, 'Dentist appointment');
      expect(intent.date, DateTime(2026, 11, 5));
      expect(intent.time, const ClockTime(10, 30));
    });

    test('a forced type is used as chosen', () {
      final intent = parse('book the thing for friday', as: VoiceIntentType.task);
      expect(intent.type, VoiceIntentType.task);
      expect(intent.title, 'Book the thing');
      expect(intent.date, DateTime(2026, 11, 6));
    });

    test('an alarm needs a time to be understood', () {
      expect(parse('set an alarm').isUnderstood, isFalse);
    });
  });

  group('dates', () {
    test('relative days', () {
      expect(parse('remind me to pay rent today').date, DateTime(2026, 10, 30));
      expect(parse('remind me to pay rent the day after tomorrow').date,
          DateTime(2026, 11, 1));
      expect(parse('remind me to pay rent in 2 days').date, DateTime(2026, 11, 1));
      expect(parse('remind me to pay rent in a week').date, DateTime(2026, 11, 6));
      expect(parse('remind me to pay rent next week').date, DateTime(2026, 11, 2));
    });

    test('weekdays', () {
      // Today is Friday, so "Friday" is next week's.
      expect(parse('remind me to call on Friday').date, DateTime(2026, 11, 6));
      expect(parse('remind me to call this Friday').date, DateTime(2026, 10, 30));
      expect(parse('remind me to call on Monday').date, DateTime(2026, 11, 2));
      expect(parse('remind me to call next Tuesday').date, DateTime(2026, 11, 3));
    });

    test('day and month in either order, rolling into next year', () {
      expect(parse('remind me to pay rent on December 1st').date,
          DateTime(2026, 12, 1));
      expect(parse('remind me to renew the licence on the 3rd of March').date,
          DateTime(2027, 3, 3));
      expect(parse('remind me to call on 31 February').date, isNull);
    });
  });

  group('times', () {
    test('am, pm and 24-hour forms', () {
      expect(parse('remind me to leave at 7 pm').time, const ClockTime(19, 0));
      expect(parse('remind me to leave at 12 am').time, const ClockTime(0, 0));
      expect(parse('Set an alarm for 18h30').time, const ClockTime(18, 30));
      expect(parse('remind me to leave at 18:45').time, const ClockTime(18, 45));
      expect(parse('remind me to leave 9.15 am').time, const ClockTime(9, 15));
    });

    test('spoken forms', () {
      expect(parse('wake me up at quarter to six').time, const ClockTime(5, 45));
      expect(parse('remind me to eat at noon').time, const ClockTime(12, 0));
      expect(parse('remind me to sleep at midnight').time, const ClockTime(0, 0));
      expect(parse('remind me to call at half past four').time,
          const ClockTime(16, 30));
      expect(parse("remind me to call at ten o'clock").time,
          const ClockTime(10, 0));
    });

    test('early hours mean the afternoon except for alarms', () {
      expect(parse('remind me to call mom at 5').time, const ClockTime(17, 0));
      expect(parse('wake me at 5').time, const ClockTime(5, 0));
      expect(parse('remind me to run tomorrow morning at 5').time,
          const ClockTime(5, 0));
      expect(parse('remind me to take out the bins tonight at 8').time,
          const ClockTime(20, 0));
      expect(parse('remind me to take out the bins tonight at 8').date,
          DateTime(2026, 10, 30));
    });

    test('ranges share am or pm', () {
      final braai = parse('schedule an event called braai on Saturday from 1 to 6 pm');
      expect(braai.title, 'Braai');
      expect(braai.time, const ClockTime(13, 0));
      expect(braai.endTime, const ClockTime(18, 0));

      final late = parse('meeting from 11 to 1 pm');
      expect(late.time, const ClockTime(11, 0));
      expect(late.endTime, const ClockTime(13, 0));

      final work = parse('team meeting tomorrow from 10 to 11:30');
      expect(work.time, const ClockTime(10, 0));
      expect(work.endTime, const ClockTime(11, 30));
    });

    test('plain numbers are not mistaken for times', () {
      final intent = parse('add buy 2 apples tomorrow');
      expect(intent.type, VoiceIntentType.task);
      expect(intent.time, isNull);
      expect(intent.title, 'Buy 2 apples');
    });
  });

  test('ClockTime clamps minutes into one day', () {
    expect(ClockTime.fromMinutes(-5), const ClockTime(0, 0));
    expect(ClockTime.fromMinutes(25 * 60), const ClockTime(23, 59));
    expect(ClockTime.fromMinutes(14 * 60 + 5), const ClockTime(14, 5));
  });
}
