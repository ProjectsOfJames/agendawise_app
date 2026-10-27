import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/notes_dao.dart';
import '../../../core/database/daos/tasks_dao.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/domain/task_priority.dart';
import '../../../core/errors/validation_exception.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/id_generator.dart';

/// Values entered on the task form. Links to events and alarms are managed
/// separately so that cross-record changes stay in one place.
class TaskDraft {
  const TaskDraft({
    required this.title,
    this.priority = TaskPriority.medium,
    this.dueAt,
    this.isAllDay = false,
    this.categoryId,
  });

  final String title;
  final TaskPriority priority;
  final DateTime? dueAt;

  /// True when a due date was given without a time.
  final bool isAllDay;
  final String? categoryId;
}

class TaskRepository {
  TaskRepository(this._tasks, this._notes, this._ids, this._clock);

  final TasksDao _tasks;
  final NotesDao _notes;
  final IdGenerator _ids;
  final Clock _clock;

  Stream<List<Task>> watchOpen() => _tasks.watchOpen();

  Stream<List<Task>> watchCompleted() => _tasks.watchCompleted();

  Stream<List<Task>> watchDueBetween(DateTime from, DateTime to) =>
      _tasks.watchDueBetween(from, to);

  Future<Task?> getById(String id) => _tasks.getById(id);

  Future<Task?> getByEventId(String eventId) => _tasks.getByEventId(eventId);

  Future<String> create(TaskDraft draft) async {
    final id = _ids.next();
    await _tasks.insertTask(
      TasksCompanion.insert(
        id: id,
        title: _validTitle(draft.title),
        priority: Value(draft.priority),
        dueAt: Value(draft.dueAt),
        isAllDay: Value(draft.dueAt != null && draft.isAllDay),
        categoryId: Value(draft.categoryId),
        createdAt: _clock(),
      ),
    );
    return id;
  }

  Future<void> update(String id, TaskDraft draft) => _tasks.updateTask(
        id,
        TasksCompanion(
          title: Value(_validTitle(draft.title)),
          priority: Value(draft.priority),
          dueAt: Value(draft.dueAt),
          isAllDay: Value(draft.dueAt != null && draft.isAllDay),
          categoryId: Value(draft.categoryId),
        ),
      );

  /// Sets both columns together to satisfy the completion CHECK constraint.
  Future<void> setDone(String id, bool done) => _tasks.updateTask(
        id,
        TasksCompanion(
          isDone: Value(done),
          completedAt: Value(done ? _clock() : null),
        ),
      );

  Future<void> setLinks(
    String id, {
    Value<String?> eventId = const Value.absent(),
    Value<String?> alarmId = const Value.absent(),
  }) =>
      _tasks.updateTask(id, TasksCompanion(eventId: eventId, alarmId: alarmId));

  /// Notes are removed by ON DELETE CASCADE.
  Future<void> delete(String id) => _tasks.deleteTask(id);

  Stream<List<Note>> watchNotes(String taskId) => _notes.watchForTask(taskId);

  Future<List<Note>> getNotes(String taskId) => _notes.getForTask(taskId);

  Future<String> addNote(String taskId, String body) async {
    final id = _ids.next();
    await _notes.insertNote(
      NotesCompanion.insert(
        id: id,
        taskId: taskId,
        body: body.trim(),
        createdAt: _clock(),
      ),
    );
    return id;
  }

  Future<void> updateNote(String id, String body) =>
      _notes.updateBody(id, body.trim());

  Future<void> deleteNote(String id) => _notes.deleteNote(id);

  String _validTitle(String title) {
    final clean = title.trim();
    if (clean.isEmpty) {
      throw const ValidationException('A title is required');
    }
    return clean;
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return TaskRepository(
    database.tasksDao,
    database.notesDao,
    ref.watch(idGeneratorProvider),
    ref.watch(clockProvider),
  );
});
