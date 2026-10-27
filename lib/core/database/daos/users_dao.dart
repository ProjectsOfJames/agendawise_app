import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.attachedDatabase);

  SimpleSelectStatement<$UsersTable, User> get _first =>
      select(users)..limit(1);

  Future<User?> getAccount() => _first.getSingleOrNull();

  Stream<User?> watchAccount() => _first.watchSingleOrNull();

  Future<int> countAccounts() async {
    final count = users.id.count();
    final row = await (selectOnly(users)..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> insertAccount(UsersCompanion user) => into(users).insert(user);

  Future<int> updateAccount(String id, UsersCompanion changes) =>
      (update(users)..where((u) => u.id.equals(id))).write(changes);

  Future<int> deleteAll() => delete(users).go();
}
