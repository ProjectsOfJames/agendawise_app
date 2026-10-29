import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/users_dao.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/utils/clock.dart';

/// On-device copy of the signed-in account's profile, keyed by the Firebase
/// user id. Passwords are never stored here; the hash and salt columns stay
/// empty. The profile picture path lives only in this table.
class UserRepository {
  UserRepository(this._dao, this._clock);

  final UsersDao _dao;
  final Clock _clock;

  Future<User?> getCached() => _dao.getAccount();

  Stream<User?> watchCached() => _dao.watchAccount();

  /// Stores [uid]'s name and email. A profile cached for a different account
  /// is replaced, together with its picture path.
  Future<void> cacheProfile({
    required String uid,
    required String fullName,
    required String email,
  }) async {
    final existing = await _dao.getAccount();
    final name = fullName.trim().isEmpty ? email : fullName.trim();
    if (existing != null && existing.id == uid) {
      await _dao.updateAccount(
        uid,
        UsersCompanion(fullName: Value(name), email: Value(email)),
      );
      return;
    }
    await _dao.deleteAll();
    await _dao.insertAccount(
      UsersCompanion.insert(
        id: uid,
        fullName: name,
        email: email,
        passwordHash: '',
        salt: '',
        createdAt: _clock(),
      ),
    );
  }

  Future<void> updateImagePath(String uid, String? imagePath) =>
      _dao.updateAccount(uid, UsersCompanion(imagePath: Value(imagePath)));

  Future<void> clear() => _dao.deleteAll();
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(
    ref.watch(appDatabaseProvider).usersDao,
    ref.watch(clockProvider),
  ),
);
