import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

/// Registers alarms with the system so they ring at their next trigger.
abstract interface class AlarmScheduler {
  /// Replaces any schedule already registered for [alarm].
  Future<void> schedule(Alarm alarm);

  Future<void> cancel(String alarmId);
}

/// Used until the ringing service and its permission flow exist.
class NoopAlarmScheduler implements AlarmScheduler {
  const NoopAlarmScheduler();

  @override
  Future<void> schedule(Alarm alarm) async {}

  @override
  Future<void> cancel(String alarmId) async {}
}

final alarmSchedulerProvider = Provider<AlarmScheduler>(
  (ref) => const NoopAlarmScheduler(),
);
