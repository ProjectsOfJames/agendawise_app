import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/application/account_providers.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';

/// The signed-in user's admin role; [AdminStatus.none] when signed out or
/// offline.
final adminStatusProvider = FutureProvider.autoDispose<AdminStatus>((ref) async {
  final account = ref.watch(currentAccountProvider);
  final repo = ref.watch(adminRepositoryProvider);
  if (account == null || repo == null) return AdminStatus.none;
  return repo.status();
});

final adminSummaryProvider = FutureProvider.autoDispose<AdminSummary>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  if (repo == null) throw const AdminException('Not available offline.');
  return repo.summary();
});

final latestLogsProvider = FutureProvider.autoDispose<List<LogEntry>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  if (repo == null) return const [];
  return repo.latest();
});

final adminListProvider = FutureProvider.autoDispose<List<AdminInfo>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  if (repo == null) return const [];
  return repo.admins();
});
