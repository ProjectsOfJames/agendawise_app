import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/categories_dao.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/errors/validation_exception.dart';
import '../../../core/utils/id_generator.dart';

final _hexColour = RegExp(r'^#[0-9A-Fa-f]{6}$');

class CategoryRepository {
  CategoryRepository(this._dao, this._ids);

  final CategoriesDao _dao;
  final IdGenerator _ids;

  Stream<List<TaskCategory>> watchAll() => _dao.watchAll();

  Future<List<TaskCategory>> getAll() => _dao.getAll();

  Future<TaskCategory?> getById(String id) => _dao.getById(id);

  Future<String> create({required String name, required String colour}) async {
    final cleanName = await _validName(name);
    _checkColour(colour);
    final id = _ids.next();
    await _dao.insertCategory(
      CategoriesCompanion.insert(id: id, name: cleanName, colour: colour),
    );
    return id;
  }

  Future<void> update(
    String id, {
    required String name,
    required String colour,
  }) async {
    final cleanName = await _validName(name, excludeId: id);
    _checkColour(colour);
    await _dao.updateCategory(
      id,
      CategoriesCompanion(name: Value(cleanName), colour: Value(colour)),
    );
  }

  /// Tasks in the category become uncategorised through ON DELETE SET NULL.
  Future<void> delete(String id) => _dao.deleteCategory(id);

  Future<String> _validName(String name, {String? excludeId}) async {
    final clean = name.trim();
    if (clean.isEmpty) {
      throw const ValidationException('A category name is required');
    }
    final existing = await _dao.findByName(clean);
    if (existing != null && existing.id != excludeId) {
      throw const ValidationException('A category with this name already exists');
    }
    return clean;
  }

  void _checkColour(String colour) {
    if (!_hexColour.hasMatch(colour)) {
      throw const ValidationException('Colour must be in the form #RRGGBB');
    }
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(
    ref.watch(appDatabaseProvider).categoriesDao,
    ref.watch(idGeneratorProvider),
  ),
);
