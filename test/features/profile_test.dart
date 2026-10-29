import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/core/database/database_provider.dart';
import 'package:agendawise/core/theme/theme_mode_provider.dart';
import 'package:agendawise/features/account/application/account_providers.dart';
import 'package:agendawise/features/account/data/account_service.dart';
import 'package:agendawise/features/account/domain/account.dart';
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

  test('without Firebase there is no account and sign-in explains why',
      () async {
    final container = containerFor();
    final sub = container.listen(currentAccountProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();

    expect(container.read(currentAccountProvider), isNull);
    await expectLater(
      container
          .read(accountServiceProvider)
          .signIn(email: 'a@b.co', password: 'password1'),
      throwsA(isA<AccountException>()),
    );
  });
}
