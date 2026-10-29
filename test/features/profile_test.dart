import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/core/database/database_provider.dart';
import 'package:agendawise/core/theme/theme_mode_provider.dart';
import 'package:agendawise/features/account/application/account_providers.dart';
import 'package:agendawise/features/account/data/user_repository.dart';
import 'package:agendawise/features/settings/data/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  ProviderContainer containerFor() {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('the theme choice is saved and restored by a new session', () async {
    final first = containerFor();
    expect(first.read(themeModeProvider), ThemeMode.light);
    await first.read(themeModeProvider.notifier).set(ThemeMode.dark);

    final second = containerFor();
    expect(second.read(themeModeProvider), ThemeMode.light);
    await second.read(themeModeProvider.notifier).restore();
    expect(second.read(themeModeProvider), ThemeMode.dark);
  });

  test('an account counts as signed in only when its id is saved', () async {
    final container = containerFor();
    final sub = container.listen(currentAccountProvider, (_, _) {});
    addTearDown(sub.close);

    final id = await container.read(userRepositoryProvider).create(
          fullName: 'Thandi Nkosi',
          email: 'thandi@example.com',
          passwordHash: 'hash',
          salt: 'salt',
        );
    await pumpEventQueue();
    expect(container.read(currentAccountProvider), isNull);

    await container
        .read(settingsRepositoryProvider)
        .setString(SettingsKeys.signedInUserId, id);
    await pumpEventQueue();
    expect(container.read(currentAccountProvider)?.fullName, 'Thandi Nkosi');
  });
}
