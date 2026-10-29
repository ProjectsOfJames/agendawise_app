import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/features/alarms/domain/alarm_days.dart';
import 'package:agendawise/features/calendar/domain/calendar_agenda.dart';
import 'package:agendawise/features/tasks/domain/task_form.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';
import '../helpers/test_services.dart';

void main() {
  late AppDatabase db;
  late TestServices s;
  late RecordingAlarmScheduler scheduler;
  final due = DateTime(2026, 11, 2, 9);

  setUp(() {
    db = openTestDatabase();
    // Clock starts at 2026-11-02 08:00.
    s = TestServices(db, SteppingClock().call);
    scheduler = s.scheduler as RecordingAlarmScheduler;
  });
  tearDown(() => db.close());

  Future<Task> task(String id) async => (await s.tasks.getById(id))!;

  test('a task due at 09:00 gets an automatic event from 09:00 to 10:00',
      () async {
    final id = await s.integration.saveTask(TaskForm(title: 'Report', dueAt: due));
    final event = (await s.events.getById((await task(id)).eventId!))!;
    expect(event.isAuto, isTrue);
    expect(event.title, 'Report');
    expect(event.startAt, due);
    expect(event.endAt, DateTime(2026, 11, 2, 10));
  });

  test('a task with a date but no time gets an all-day event', () async {
    final id = await s.integration.saveTask(
      TaskForm(title: 'Pay rent', dueAt: DateTime(2026, 11, 3), isAllDay: true),
    );
    final event = (await s.events.getById((await task(id)).eventId!))!;
    expect(event.isAllDay, isTrue);
    expect(event.startAt, DateTime(2026, 11, 3));
  });

  test('editing the due date moves the event; removing it deletes the event',
      () async {
    final id = await s.integration.saveTask(TaskForm(title: 'Report', dueAt: due));
    final eventId = (await task(id)).eventId!;

    await s.integration.saveTask(
      TaskForm(title: 'Final report', dueAt: DateTime(2026, 11, 4, 14)),
      id: id,
    );
    final moved = (await s.events.getById(eventId))!;
    expect(moved.title, 'Final report');
    expect(moved.startAt, DateTime(2026, 11, 4, 14));
    expect((await task(id)).eventId, eventId);

    await s.integration.saveTask(const TaskForm(title: 'Final report'), id: id);
    expect(await s.events.getById(eventId), isNull);
    expect((await task(id)).eventId, isNull);
  });

  test('the automatic event takes the category colour', () async {
    final categoryId =
        await s.categories.create(name: 'Work', colour: '#F97316');
    final id = await s.integration
        .saveTask(TaskForm(title: 'Report', dueAt: due, categoryId: categoryId));
    final event = (await s.events.getById((await task(id)).eventId!))!;
    expect(event.colour, '#F97316');
  });

  test('deleting a task deletes its automatic event and linked alarm',
      () async {
    final id = await s.integration.saveTask(
      TaskForm(title: 'Report', dueAt: due, linkedAlarm: true),
    );
    final linked = await task(id);
    await s.integration.deleteTask(id);
    expect(await s.tasks.getById(id), isNull);
    expect(await s.events.getById(linked.eventId!), isNull);
    expect(await s.alarms.getById(linked.alarmId!), isNull);
    expect(scheduler.cancelled, contains(linked.alarmId));
  });

  test('deleting an event only unlinks the task', () async {
    final id = await s.integration.saveTask(TaskForm(title: 'Report', dueAt: due));
    final eventId = (await task(id)).eventId!;
    await s.events.delete(eventId);
    expect((await task(id)).eventId, isNull);
    expect(await s.tasks.getById(id), isNotNull);
  });

  test('a linked alarm rings on the due date and time and is scheduled',
      () async {
    final id = await s.integration.saveTask(
      TaskForm(
          title: 'Report', dueAt: DateTime(2026, 11, 5, 7, 30), linkedAlarm: true),
    );
    final alarm = (await s.alarms.getById((await task(id)).alarmId!))!.alarm;
    expect(alarm.title, 'Report');
    expect(alarm.hour, 7);
    expect(alarm.minute, 30);
    expect(alarm.ringOn, DateTime(2026, 11, 5));
    expect(nextAlarmTrigger(alarm, DateTime(2026, 11, 2, 8)),
        DateTime(2026, 11, 5, 7, 30));
    expect(scheduler.scheduled, [alarm.id]);
  });

  test('unticking the linked alarm deletes it; all-day tasks get none',
      () async {
    final id = await s.integration
        .saveTask(TaskForm(title: 'Report', dueAt: due, linkedAlarm: true));
    final alarmId = (await task(id)).alarmId!;

    await s.integration.saveTask(TaskForm(title: 'Report', dueAt: due), id: id);
    expect(await s.alarms.getById(alarmId), isNull);
    expect((await task(id)).alarmId, isNull);

    final allDay = await s.integration.saveTask(TaskForm(
      title: 'Holiday',
      dueAt: DateTime(2026, 11, 6),
      isAllDay: true,
      linkedAlarm: true,
    ));
    expect((await task(allDay)).alarmId, isNull);
  });

  test('completing switches the linked alarm off; reopening switches it on',
      () async {
    final id = await s.integration
        .saveTask(TaskForm(title: 'Report', dueAt: due, linkedAlarm: true));
    final alarmId = (await task(id)).alarmId!;

    await s.integration.setTaskDone(await task(id), true);
    expect((await s.alarms.getById(alarmId))!.alarm.isActive, isFalse);

    await s.integration.setTaskDone(await task(id), false);
    expect((await s.alarms.getById(alarmId))!.alarm.isActive, isTrue);
  });

  test('the calendar lists the task once, without its event or alarm',
      () async {
    final id = await s.integration
        .saveTask(TaskForm(title: 'Report', dueAt: due, linkedAlarm: true));
    final linked = await task(id);
    final agenda = CalendarAgenda.build(
      month: DateTime(2026, 11),
      events: [(await s.events.getById(linked.eventId!))!],
      tasks: [linked],
      alarms: [(await s.alarms.getById(linked.alarmId!))!.alarm],
      now: DateTime(2026, 11, 2, 8),
    );
    final items = agenda.itemsOn(DateTime(2026, 11, 2));
    expect(items, hasLength(1));
    expect(items.single.kind, AgendaKind.task);
  });
}
