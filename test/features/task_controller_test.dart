import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/core/domain/interaction_event_type.dart';
import 'package:agendawise/core/domain/task_priority.dart';
import 'package:agendawise/core/errors/validation_exception.dart';
import 'package:agendawise/core/utils/id_generator.dart';
import 'package:agendawise/features/difficulty/data/interaction_log_repository.dart';
import 'package:agendawise/features/difficulty/data/interaction_logger.dart';
import 'package:agendawise/features/tasks/application/task_controller.dart';
import 'package:agendawise/features/tasks/data/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late TaskController controller;
  late TaskRepository tasks;
  late InteractionLogRepository logs;

  setUp(() {
    db = openTestDatabase();
    final clock = SteppingClock();
    const ids = IdGenerator();
    tasks = TaskRepository(db.tasksDao, db.notesDao, ids, clock.call);
    controller = TaskController(
      tasks,
      InteractionLogger(db.interactionLogsDao, ids, clock.call),
    );
    logs = InteractionLogRepository(db.interactionLogsDao);
  });
  tearDown(() => db.close());

  test('quick add stores title and priority', () async {
    final id = await controller.quickAdd('  Call dentist ', TaskPriority.high);
    final task = await tasks.getById(id);
    expect(task!.title, 'Call dentist');
    expect(task.priority, TaskPriority.high);
  });

  test('quick add rejects a blank title', () async {
    await expectLater(
      controller.quickAdd('   ', TaskPriority.medium),
      throwsA(isA<ValidationException>()),
    );
  });

  test('completing logs once; reopening and repeating do not log', () async {
    final id = await controller.quickAdd('Report', TaskPriority.medium);

    await controller.setDone((await tasks.getById(id))!, true);
    await controller.setDone((await tasks.getById(id))!, true);
    expect(await logs.count(InteractionEventType.taskCompleted), 1);

    await controller.setDone((await tasks.getById(id))!, false);
    expect((await tasks.getById(id))!.isDone, isFalse);
    expect(await logs.count(InteractionEventType.taskCompleted), 1);
  });

  test('save creates a task with fields and a note', () async {
    final due = DateTime(2026, 11, 2, 9);
    final id = await controller.save(
      TaskForm(
        title: 'Submit report',
        priority: TaskPriority.low,
        dueAt: due,
        note: 'Attach figures',
      ),
    );
    final loaded = await controller.load(id);
    expect(loaded!.task.title, 'Submit report');
    expect(loaded.task.priority, TaskPriority.low);
    expect(loaded.task.dueAt, due);
    expect(loaded.note!.body, 'Attach figures');
  });

  test('save updates fields and the note, and clears an emptied note',
      () async {
    final id = await controller.save(
      const TaskForm(title: 'Draft', note: 'First'),
    );

    await controller.save(
      const TaskForm(title: 'Final', priority: TaskPriority.high, note: 'Second'),
      id: id,
    );
    var loaded = await controller.load(id);
    expect(loaded!.task.title, 'Final');
    expect(loaded.task.priority, TaskPriority.high);
    expect(loaded.note!.body, 'Second');
    expect(await tasks.getNotes(id), hasLength(1));

    await controller.save(const TaskForm(title: 'Final', note: '  '), id: id);
    loaded = await controller.load(id);
    expect(loaded!.note, isNull);
  });

  test('all-day due date keeps the flag', () async {
    final id = await controller.save(
      TaskForm(title: 'Pay rent', dueAt: DateTime(2026, 11, 1), isAllDay: true),
    );
    expect((await tasks.getById(id))!.isAllDay, isTrue);
  });

  test('load returns null for a missing task; delete removes it', () async {
    expect(await controller.load('missing'), isNull);
    final id = await controller.quickAdd('Temp', TaskPriority.low);
    await controller.delete(id);
    expect(await controller.load(id), isNull);
  });
}
