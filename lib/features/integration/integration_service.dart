import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/utils/clock.dart';
import '../alarms/application/alarm_scheduler.dart';
import '../alarms/data/alarm_repository.dart';
import '../calendar/data/event_repository.dart';
import '../categories/data/category_repository.dart';
import '../difficulty/data/interaction_logger.dart';
import '../tasks/data/task_repository.dart';
import '../tasks/domain/task_form.dart';

/// Colour of automatic events whose task has no category.
const autoEventColour = '#06B6D4';

/// Length of the automatic event for a task with a due time.
const autoEventLength = Duration(hours: 1);

/// Keeps tasks, their automatic calendar events and their linked alarms
/// consistent. It is the only class that writes across those records.
///
/// Rules:
/// - a task with a due date has one automatic event: one hour from the due
///   time, or all day when no time was given;
/// - a task may have a linked one-off alarm at its due date and time;
/// - deleting a task deletes its automatic event and its linked alarm;
/// - completing a task switches its linked alarm off, reopening switches it
///   back on if the due time is still ahead;
/// - deleting an event or an alarm only clears the link on the task
///   (handled by the database's ON DELETE SET NULL).
class IntegrationService {
  IntegrationService({
    required AppDatabase database,
    required TaskRepository tasks,
    required EventRepository events,
    required AlarmRepository alarms,
    required CategoryRepository categories,
    required AlarmScheduler alarmScheduler,
    required InteractionLogger logger,
    required Clock clock,
  })  : _db = database,
        _tasks = tasks,
        _events = events,
        _alarms = alarms,
        _categories = categories,
        _scheduler = alarmScheduler,
        _logger = logger,
        _clock = clock;

  final AppDatabase _db;
  final TaskRepository _tasks;
  final EventRepository _events;
  final AlarmRepository _alarms;
  final CategoryRepository _categories;
  final AlarmScheduler _scheduler;
  final InteractionLogger _logger;
  final Clock _clock;

  /// Creates the task when [id] is null, otherwise updates it, together with
  /// its note, automatic event and linked alarm. Returns the task id.
  Future<String> saveTask(TaskForm form, {String? id}) async {
    late String taskId;
    final alarmChanges = _AlarmChanges();

    await _db.transaction(() async {
      final draft = form.toDraft();
      taskId = id ?? await _tasks.create(draft);
      if (id != null) await _tasks.update(id, draft);
      await _saveNote(taskId, form.note);

      final task = (await _tasks.getById(taskId))!;
      await _syncEvent(task);
      await _syncAlarm(task, wanted: form.linkedAlarm, changes: alarmChanges);
    });

    await alarmChanges.apply(_alarms, _scheduler);
    return taskId;
  }

  /// Deletes the task, its notes, its automatic event and its linked alarm.
  Future<void> deleteTask(String id) async {
    String? alarmId;
    await _db.transaction(() async {
      final task = await _tasks.getById(id);
      if (task == null) return;
      final eventId = task.eventId;
      if (eventId != null) {
        final event = await _events.getById(eventId);
        if (event != null && event.isAuto) await _events.delete(eventId);
      }
      alarmId = task.alarmId;
      if (alarmId != null) await _alarms.delete(alarmId!);
      await _tasks.delete(id);
    });
    final removed = alarmId;
    if (removed != null) await _scheduler.cancel(removed);
  }

  /// Marks the task done or open and updates its linked alarm to match.
  Future<void> setTaskDone(Task task, bool done) async {
    if (task.isDone == done) return;
    await _tasks.setDone(task.id, done);
    if (done) await _logger.taskCompleted(task.id);

    final alarmId = task.alarmId;
    if (alarmId == null) return;
    final linked = (await _alarms.getById(alarmId))?.alarm;
    if (linked == null) return;
    final due = task.dueAt;
    final shouldRing = !done && due != null && due.isAfter(_clock());
    await _alarms.setActive(alarmId, shouldRing);
    final updated = (await _alarms.getById(alarmId))?.alarm;
    if (shouldRing && updated != null) {
      await _scheduler.schedule(updated);
    } else {
      await _scheduler.cancel(alarmId);
    }
  }

  Future<void> _syncEvent(Task task) async {
    final eventId = task.eventId;
    final existing = eventId == null ? null : await _events.getById(eventId);
    final due = task.dueAt;

    if (due == null) {
      if (existing != null && existing.isAuto) await _events.delete(existing.id);
      return;
    }

    final draft = EventDraft(
      title: task.title,
      startAt: task.isAllDay ? DateTime(due.year, due.month, due.day) : due,
      endAt: task.isAllDay
          ? DateTime(due.year, due.month, due.day, 23, 59)
          : due.add(autoEventLength),
      isAllDay: task.isAllDay,
      colour: await _colourFor(task),
    );
    if (existing != null && existing.isAuto) {
      await _events.update(existing.id, draft);
    } else {
      final newId = await _events.create(draft, isAuto: true);
      await _tasks.setLinks(task.id, eventId: Value(newId));
    }
  }

  Future<void> _syncAlarm(
    Task task, {
    required bool wanted,
    required _AlarmChanges changes,
  }) async {
    final due = task.dueAt;
    final alarmId = task.alarmId;
    final linked = alarmId == null ? null : await _alarms.getById(alarmId);
    final existing = linked?.alarm;
    final challenge = linked?.challenge;

    if (!wanted || due == null || task.isAllDay) {
      if (existing != null) {
        await _alarms.delete(existing.id);
        changes.cancel.add(existing.id);
      }
      return;
    }

    // Keeps any sound, snooze or challenge settings chosen for the alarm.
    final draft = AlarmDraft(
      hour: due.hour,
      minute: due.minute,
      title: task.title,
      ringOn: due,
      snoozeMinutes: existing?.snoozeMinutes ?? 5,
      snoozeLimit: existing?.snoozeLimit,
      soundRef: existing?.soundRef ?? 'tone_1',
      vibrate: existing?.vibrate ?? true,
      isActive: !task.isDone && due.isAfter(_clock()),
      challengeType: challenge?.challengeType,
    );
    if (existing != null) {
      await _alarms.update(existing.id, draft);
      changes.schedule.add(existing.id);
    } else {
      final newId = await _alarms.create(draft);
      await _tasks.setLinks(task.id, alarmId: Value(newId));
      changes.schedule.add(newId);
    }
  }

  Future<String> _colourFor(Task task) async {
    final categoryId = task.categoryId;
    if (categoryId == null) return autoEventColour;
    return (await _categories.getById(categoryId))?.colour ?? autoEventColour;
  }

  Future<void> _saveNote(String taskId, String text) async {
    final body = text.trim();
    final existing = await _tasks.getNotes(taskId);
    if (existing.isEmpty) {
      if (body.isNotEmpty) await _tasks.addNote(taskId, body);
      return;
    }
    final first = existing.first;
    if (body.isEmpty) {
      await _tasks.deleteNote(first.id);
    } else if (body != first.body) {
      await _tasks.updateNote(first.id, body);
    }
  }
}

/// Alarm schedule changes collected inside a transaction and applied after
/// it commits, so the system never holds an alarm the database rolled back.
class _AlarmChanges {
  final schedule = <String>[];
  final cancel = <String>[];

  Future<void> apply(AlarmRepository alarms, AlarmScheduler scheduler) async {
    for (final id in cancel) {
      await scheduler.cancel(id);
    }
    for (final id in schedule) {
      final alarm = (await alarms.getById(id))?.alarm;
      if (alarm == null) continue;
      if (alarm.isActive) {
        await scheduler.schedule(alarm);
      } else {
        await scheduler.cancel(id);
      }
    }
  }
}

final integrationServiceProvider = Provider<IntegrationService>(
  (ref) => IntegrationService(
    database: ref.watch(appDatabaseProvider),
    tasks: ref.watch(taskRepositoryProvider),
    events: ref.watch(eventRepositoryProvider),
    alarms: ref.watch(alarmRepositoryProvider),
    categories: ref.watch(categoryRepositoryProvider),
    alarmScheduler: ref.watch(alarmSchedulerProvider),
    logger: ref.watch(interactionLoggerProvider),
    clock: ref.watch(clockProvider),
  ),
);
