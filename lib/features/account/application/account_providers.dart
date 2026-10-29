import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_service.dart';
import '../domain/account.dart';

final _accountStreamProvider = StreamProvider<Account?>(
  (ref) => ref.watch(accountServiceProvider).watch(),
);

/// The signed-in online account, or null when signed out.
final currentAccountProvider = Provider<Account?>(
  (ref) => ref.watch(_accountStreamProvider).asData?.value,
);

/// Whether the signed-in user shares anonymous usage events.
final usageOptInProvider = FutureProvider.autoDispose<bool>((ref) {
  ref.watch(currentAccountProvider);
  return ref.watch(accountServiceProvider).usageOptIn();
});
