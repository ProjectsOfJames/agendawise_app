import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/category_repository.dart';

final categoriesProvider = StreamProvider<List<TaskCategory>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

/// Categories keyed by id, for looking up a task's category quickly.
final categoriesByIdProvider = Provider<Map<String, TaskCategory>>((ref) {
  final categories = ref.watch(categoriesProvider).asData?.value ?? const [];
  return {for (final category in categories) category.id: category};
});
