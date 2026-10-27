import 'package:agendawise/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

AppDatabase openTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Returns a later time on every call so ordering by timestamp is stable.
class SteppingClock {
  SteppingClock([DateTime? start, this.step = const Duration(seconds: 1)])
      : _next = start ?? DateTime(2026, 11, 2, 8);

  final Duration step;
  DateTime _next;

  DateTime call() {
    final now = _next;
    _next = _next.add(step);
    return now;
  }
}
