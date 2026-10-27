import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/domain/task_priority.dart';
import '../../difficulty/data/interaction_logger.dart';
import '../data/task_repository.dart';

/// Everything the task screens edit: the task fields plus its single note.
class TaskForm {
  const TaskForm({
    required this.title,
    this.priority = TaskPriority.medium,
    this.dueAt,
    this.isAllDay = false,
    this.categoryId,
    this.note = '',
  });

  final String title;
  final TaskPriority priority;
  final DateTime? dueAt;
  final bool isAllDay;
  final String? categoryId;
  final String note;

  TaskDraft toDraft() => TaskDraft(
        title: title,
        priority: priority,
        dueAt: dueAt,
        isAllDay: isAllDay,
        categoryId: categoryId,
      );
}

/// A stored task with its note, ready to fill the detail form.
class LoadedTask {
  const LoadedTask(this.task, this.note);

  final Task task;
  final Note? note;
}

/// Task use cases for the To-Do screens.
class TaskController {
  TaskController(this._tasks, this._logger);

  final TaskRepository _tasks;
  final InteractionLogger _logger;

  Future<String> quickAdd(String title, TaskPriority priority) =>
      _tasks.create(TaskDraft(title: title, priority: priority));

  Future<void> setDone(Task task, bool done) async {
    if (task.isDone == done) return;
    await _tasks.setDone(task.id, done);
    if (done) await _logger.taskCompleted(task.id);
  }

  Future<void> delete(String id) => _tasks.delete(id);

  Future<LoadedTask?> load(String id) async {
    final task = await _tasks.getById(id);
    if (task == null) return null;
    final notes = await _tasks.getNotes(id);
    return LoadedTask(task, notes.isEmpty ? null : notes.first);
  }

  /// Creates the task when [id] is null, otherwise updates it.
  /// Returns the task id.
  Future<String> save(TaskForm form, {String? id}) async {
    final draft = form.toDraft();
    final taskId = id ?? await _tasks.create(draft);
    if (id != null) await _tasks.update(id, draft);
    await _saveNote(taskId, form.note);
    return taskId;
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

final taskControllerProvider = Provider<TaskController>(
  (ref) => TaskController(
    ref.watch(taskRepositoryProvider),
    ref.watch(interactionLoggerProvider),
  ),
);
