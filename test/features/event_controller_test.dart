import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/core/errors/validation_exception.dart';
import 'package:agendawise/core/utils/id_generator.dart';
import 'package:agendawise/features/calendar/application/event_controller.dart';
import 'package:agendawise/features/calendar/application/reminder_scheduler.dart';
import 'package:agendawise/features/calendar/data/event_repository.dart';
import 'package:agendawise/features/calendar/domain/repeat_rule.dart';
import 'package:agendawise/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

class _RecordingScheduler implements ReminderScheduler {
  final scheduled = <String>[];
  final cancelled = <String>[];

  @override
  Future<void> schedule(CalendarEvent event) async => scheduled.add(event.id);

  @override
  Future<void> cancel(String eventId) async => cancelled.add(eventId);
}

void main() {
  late AppDatabase db;
  late EventController controller;
  late _RecordingScheduler reminders;
  final day = DateTime(2026, 6, 15);

  setUp(() {
    db = openTestDatabase();
    reminders = _RecordingScheduler();
    controller = EventController(
      EventRepository(db.eventsDao, const IdGenerator(), SteppingClock().call),
      SettingsRepository(db.settingsDao),
      reminders,
    );
  });
  tearDown(() => db.close());

  test('blank title saves as "My event" with the chosen times', () async {
    final id = await controller.save(
      EventForm(date: day, colourHex: '#8B5CF6', startMinutes: 540, endMinutes: 600),
    );
    final event = await controller.load(id);
    expect(event!.title, 'My event');
    expect(event.startAt, DateTime(2026, 6, 15, 9));
    expect(event.endAt, DateTime(2026, 6, 15, 10));
  });

  test('end at or before start is rejected', () async {
    await expectLater(
      controller.save(EventForm(
          date: day, colourHex: '#8B5CF6', startMinutes: 600, endMinutes: 600)),
      throwsA(isA<ValidationException>()),
    );
  });

  test('all-day ignores times and covers the day', () async {
    final id = await controller.save(EventForm(
        date: day,
        colourHex: '#8B5CF6',
        isAllDay: true,
        startMinutes: 900,
        endMinutes: 100));
    final event = await controller.load(id);
    expect(event!.isAllDay, isTrue);
    expect(event.startAt, day);
    expect(event.endAt, DateTime(2026, 6, 15, 23, 59));
  });

  test('repeat and reminder are stored and reloaded into the form', () async {
    final id = await controller.save(EventForm(
      date: day,
      title: 'Standup',
      colourHex: '#06B6D4',
      reminderMinutesBefore: 60,
      repeat: const RepeatRule(RepeatUnit.weeks, 2),
      location: ' Room 4 ',
    ));
    final form = EventForm.fromEvent((await controller.load(id))!);
    expect(form.title, 'Standup');
    expect(form.repeat, const RepeatRule(RepeatUnit.weeks, 2));
    expect(form.reminderMinutesBefore, 60);
    expect(form.location, 'Room 4');
    expect(form.startMinutes, 540);
  });

  test('reminders are scheduled, cancelled when removed and on delete',
      () async {
    final id = await controller.save(
        EventForm(date: day, colourHex: '#8B5CF6', reminderMinutesBefore: 10));
    expect(reminders.scheduled, [id]);

    await controller.save(
      EventForm(date: day, colourHex: '#8B5CF6', reminderMinutesBefore: null),
      id: id,
    );
    expect(reminders.cancelled, [id]);

    await controller.delete(id);
    expect(reminders.cancelled, [id, id]);
    expect(await controller.load(id), isNull);
  });

  test('custom colours are kept newest first without duplicates', () async {
    expect(await controller.customColours(), isEmpty);
    await controller.addCustomColour('#112233');
    await controller.addCustomColour('#445566');
    final colours = await controller.addCustomColour('#112233');
    expect(colours, ['#112233', '#445566']);
    expect(await controller.customColours(), ['#112233', '#445566']);
  });
}
