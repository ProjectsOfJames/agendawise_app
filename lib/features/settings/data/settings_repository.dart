import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/settings_dao.dart';
import '../../../core/database/database_provider.dart';

abstract final class SettingsKeys {
  static const themeMode = 'theme_mode';
  static const signedInUserId = 'signed_in_user_id';
}

class SettingsRepository {
  SettingsRepository(this._dao);

  final SettingsDao _dao;

  Future<String?> getString(String key) => _dao.getValue(key);

  Stream<String?> watchString(String key) => _dao.watchValue(key);

  Future<void> setString(String key, String value) => _dao.setValue(key, value);

  Future<void> remove(String key) => _dao.removeValue(key);

  Future<bool?> getBool(String key) async {
    final value = await _dao.getValue(key);
    return value == null ? null : value == 'true';
  }

  Future<void> setBool(String key, bool value) =>
      _dao.setValue(key, value.toString());
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider).settingsDao),
);
