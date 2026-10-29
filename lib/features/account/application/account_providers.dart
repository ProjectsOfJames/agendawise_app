import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../settings/data/settings_repository.dart';
import '../data/user_repository.dart';

final _signedInIdProvider = StreamProvider<String?>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watchString(SettingsKeys.signedInUserId),
);

final _storedAccountProvider = StreamProvider<User?>(
  (ref) => ref.watch(userRepositoryProvider).watchAccount(),
);

/// The local account when it exists and is signed in; null otherwise.
final currentAccountProvider = Provider<User?>((ref) {
  final signedInId = ref.watch(_signedInIdProvider).asData?.value;
  final account = ref.watch(_storedAccountProvider).asData?.value;
  if (account == null || signedInId != account.id) return null;
  return account;
});
