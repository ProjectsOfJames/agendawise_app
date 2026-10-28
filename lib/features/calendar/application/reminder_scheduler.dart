import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

/// Schedules the notification for an event's reminder.
abstract interface class ReminderScheduler {
  /// Replaces any reminder already scheduled for [event].
  Future<void> schedule(CalendarEvent event);

  Future<void> cancel(String eventId);
}

/// Used until the notification service and its permission flow exist.
class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  Future<void> schedule(CalendarEvent event) async {}

  @override
  Future<void> cancel(String eventId) async {}
}

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => const NoopReminderScheduler(),
);
