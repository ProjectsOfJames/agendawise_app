import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cloud/activity_actions.dart';
import '../../../core/cloud/activity_logger.dart';
import '../../../core/database/app_database.dart';
import '../../../core/domain/task_priority.dart';
import '../../integration/integration_service.dart';
import '../data/task_repository.dart';
import '../domain/task_form.dart';

export '../domain/task_form.dart';

/// A stored task with its note, ready to fill the detail form.
class LoadedTask {
  const LoadedTask(this.task, this.note);

  final Task task;
  final Note? note;
}

/// Task use cases for the To-Do screens. Changes that touch linked events
/// or alarms go through the integration service.
class TaskController {
  TaskController(
    this._tasks,
    this._integration, {
    ActivityLogger activity = const NoopActivityLogger(),
  }) : _activity = activity;

  final TaskRepository _tasks;
  final IntegrationService _integration;
  final ActivityLogger _activity;

  Future<String> quickAdd(String title, TaskPriority priority) async {
    final id = await _tasks.create(TaskDraft(title: title, priority: priority));
    _activity.log(ActivityAction.taskCreated, meta: {'dueDate': false});
    return id;
  }

  Future<void> setDone(Task task, bool done) async {
    final changed = task.isDone != done;
    await _integration.setTaskDone(task, done);
    if (changed && done) _activity.log(ActivityAction.taskCompleted);
  }

  Future<void> delete(String id) => _integration.deleteTask(id);

  Future<LoadedTask?> load(String id) async {
    final task = await _tasks.getById(id);
    if (task == null) return null;
    final notes = await _tasks.getNotes(id);
    return LoadedTask(task, notes.isEmpty ? null : notes.first);
  }

  /// Creates the task when [id] is null, otherwise updates it.
  /// Returns the task id.
  Future<String> save(TaskForm form, {String? id}) async {
    final taskId = await _integration.saveTask(form, id: id);
    if (id == null) {
      _activity.log(ActivityAction.taskCreated, meta: {
        'dueDate': form.dueAt != null,
        'linkedAlarm': form.linkedAlarm,
      });
    }
    return taskId;
  }
}

final taskControllerProvider = Provider<TaskController>(
  (ref) => TaskController(
    ref.watch(taskRepositoryProvider),
    ref.watch(integrationServiceProvider),
    activity: ref.watch(activityLoggerProvider),
  ),
);
