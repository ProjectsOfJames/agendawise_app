import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.attachedDatabase);

  Stream<List<TaskCategory>> watchAll() => (select(categories)
        ..orderBy([(c) => OrderingTerm.asc(c.name.lower())]))
      .watch();

  Future<List<TaskCategory>> getAll() => (select(categories)
        ..orderBy([(c) => OrderingTerm.asc(c.name.lower())]))
      .get();

  Future<TaskCategory?> getById(String id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Case-insensitive lookup, matching the column's NOCASE collation.
  Future<TaskCategory?> findByName(String name) => (select(categories)
        ..where((c) => c.name.lower().equals(name.trim().toLowerCase())))
      .getSingleOrNull();

  Future<void> insertCategory(CategoriesCompanion category) =>
      into(categories).insert(category);

  Future<int> updateCategory(String id, CategoriesCompanion changes) =>
      (update(categories)..where((c) => c.id.equals(id))).write(changes);

  Future<int> deleteCategory(String id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();
}
