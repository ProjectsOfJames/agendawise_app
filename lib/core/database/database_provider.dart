import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Single database instance for the app. Tests override this with an
/// in-memory database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.device();
  ref.onDispose(database.close);
  return database;
});
