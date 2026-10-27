import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.attachedDatabase);

  Stream<List<Note>> watchForTask(String taskId) => (select(notes)
        ..where((n) => n.taskId.equals(taskId))
        ..orderBy([(n) => OrderingTerm.asc(n.createdAt)]))
      .watch();

  Future<List<Note>> getForTask(String taskId) => (select(notes)
        ..where((n) => n.taskId.equals(taskId))
        ..orderBy([(n) => OrderingTerm.asc(n.createdAt)]))
      .get();

  Future<void> insertNote(NotesCompanion note) => into(notes).insert(note);

  Future<int> updateBody(String id, String body) =>
      (update(notes)..where((n) => n.id.equals(id)))
          .write(NotesCompanion(body: Value(body)));

  Future<int> deleteNote(String id) =>
      (delete(notes)..where((n) => n.id.equals(id))).go();
}
