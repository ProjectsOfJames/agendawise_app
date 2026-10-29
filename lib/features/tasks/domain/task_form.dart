import '../../../core/domain/task_priority.dart';
import '../data/task_repository.dart';

/// Everything the task screens edit: the task fields, its single note and
/// whether it should have a linked alarm.
class TaskForm {
  const TaskForm({
    required this.title,
    this.priority = TaskPriority.medium,
    this.dueAt,
    this.isAllDay = false,
    this.categoryId,
    this.note = '',
    this.linkedAlarm = false,
  });

  final String title;
  final TaskPriority priority;
  final DateTime? dueAt;
  final bool isAllDay;
  final String? categoryId;
  final String note;

  /// Only honoured when the task has a due date with a time.
  final bool linkedAlarm;

  TaskDraft toDraft() => TaskDraft(
        title: title,
        priority: priority,
        dueAt: dueAt,
        isAllDay: isAllDay,
        categoryId: categoryId,
      );
}
