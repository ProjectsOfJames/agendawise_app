import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  SimpleSelectStatement<$AppSettingsTable, AppSetting> _byKey(String key) =>
      select(appSettings)..where((s) => s.key.equals(key));

  Future<String?> getValue(String key) async =>
      (await _byKey(key).getSingleOrNull())?.value;

  Stream<String?> watchValue(String key) =>
      _byKey(key).watchSingleOrNull().map((row) => row?.value);

  Future<void> setValue(String key, String value) => into(appSettings)
      .insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  Future<int> removeValue(String key) =>
      (delete(appSettings)..where((s) => s.key.equals(key))).go();
}
