import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/users_dao.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/errors/validation_exception.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/id_generator.dart';

/// Storage for the single optional local account. Password hashing happens
/// before values reach this class.
class UserRepository {
  UserRepository(this._dao, this._ids, this._clock);

  final UsersDao _dao;
  final IdGenerator _ids;
  final Clock _clock;

  Future<User?> getAccount() => _dao.getAccount();

  Stream<User?> watchAccount() => _dao.watchAccount();

  Future<String> create({
    required String fullName,
    required String email,
    required String passwordHash,
    required String salt,
  }) async {
    if (await _dao.countAccounts() > 0) {
      throw const ValidationException('An account already exists on this device');
    }
    final id = _ids.next();
    await _dao.insertAccount(
      UsersCompanion.insert(
        id: id,
        fullName: _required(fullName, 'A name is required'),
        email: _required(email, 'An email address is required'),
        passwordHash: passwordHash,
        salt: salt,
        createdAt: _clock(),
      ),
    );
    return id;
  }

  Future<void> updateDetails(
    String id, {
    required String fullName,
    required String email,
  }) =>
      _dao.updateAccount(
        id,
        UsersCompanion(
          fullName: Value(_required(fullName, 'A name is required')),
          email: Value(_required(email, 'An email address is required')),
        ),
      );

  Future<void> updatePassword(
    String id, {
    required String passwordHash,
    required String salt,
  }) =>
      _dao.updateAccount(
        id,
        UsersCompanion(passwordHash: Value(passwordHash), salt: Value(salt)),
      );

  Future<void> updateImagePath(String id, String? imagePath) =>
      _dao.updateAccount(id, UsersCompanion(imagePath: Value(imagePath)));

  Future<void> deleteAccount() => _dao.deleteAll();

  String _required(String value, String message) {
    final clean = value.trim();
    if (clean.isEmpty) throw ValidationException(message);
    return clean;
  }
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(
    ref.watch(appDatabaseProvider).usersDao,
    ref.watch(idGeneratorProvider),
    ref.watch(clockProvider),
  ),
);
