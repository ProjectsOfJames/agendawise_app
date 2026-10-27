import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.attachedDatabase);

  /// Open tasks: dated ones first in due order, then undated by creation.
  Stream<List<Task>> watchOpen() => (select(tasks)
        ..where((t) => t.isDone.equals(false))
        ..orderBy([
          (t) => OrderingTerm.asc(t.dueAt.isNull()),
          (t) => OrderingTerm.asc(t.dueAt),
          (t) => OrderingTerm.asc(t.createdAt),
        ]))
      .watch();

  Stream<List<Task>> watchCompleted() => (select(tasks)
        ..where((t) => t.isDone.equals(true))
        ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
      .watch();

  /// Tasks due within the half-open range [from, to).
  Stream<List<Task>> watchDueBetween(DateTime from, DateTime to) =>
      (select(tasks)
            ..where((t) =>
                t.dueAt.isBiggerOrEqualValue(from.millisecondsSinceEpoch) &
                t.dueAt.isSmallerThanValue(to.millisecondsSinceEpoch))
            ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
          .watch();

  Future<Task?> getById(String id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Task?> getByEventId(String eventId) =>
      (select(tasks)..where((t) => t.eventId.equals(eventId)))
          .getSingleOrNull();

  Future<void> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<int> updateTask(String id, TasksCompanion changes) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(changes);

  Future<int> deleteTask(String id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();
}
