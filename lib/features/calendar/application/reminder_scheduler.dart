import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/platform/notification_service.dart';
import '../../../core/platform/platform_support.dart';
import '../../../core/utils/clock.dart';
import '../../alarms/domain/alarm_ids.dart';
import '../domain/reminder_time.dart';

/// Schedules the notification for an event's reminder.
abstract interface class ReminderScheduler {
  /// Replaces any reminder already scheduled for [event].
  Future<void> schedule(CalendarEvent event);

  Future<void> cancel(String eventId);
}

/// Used in tests and on platforms without notifications.
class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  Future<void> schedule(CalendarEvent event) async {}

  @override
  Future<void> cancel(String eventId) async {}
}

int reminderNotificationId(String eventId) =>
    nativeIdFor(eventId, salt: 'reminder');

/// Schedules the next reminder of each event as a local notification.
/// Repeating events get one notification at a time; the next one is
/// scheduled whenever the app starts.
class NotificationReminderScheduler implements ReminderScheduler {
  NotificationReminderScheduler(this._notifications, this._clock);

  final NotificationService _notifications;
  final Clock _clock;

  @override
  Future<void> schedule(CalendarEvent event) async {
    final id = reminderNotificationId(event.id);
    final at = nextReminderTime(event, _clock());
    try {
      if (at == null) {
        await _notifications.cancel(id);
        return;
      }
      await _notifications.schedule(
        id: id,
        at: at,
        title: event.title,
        body: _body(event),
      );
    } on Object catch (error) {
      debugPrint('Could not schedule reminder for ${event.id}: $error');
    }
  }

  @override
  Future<void> cancel(String eventId) async {
    try {
      await _notifications.cancel(reminderNotificationId(eventId));
    } on Object catch (error) {
      debugPrint('Could not cancel reminder for $eventId: $error');
    }
  }

  String _body(CalendarEvent event) {
    final minutes = event.reminderMinutesBefore ?? 0;
    final when = switch (minutes) {
      0 => 'Starting now',
      < 60 => 'Starts in $minutes min',
      _ when minutes % 1440 == 0 => 'Starts in ${minutes ~/ 1440} day'
          '${minutes ~/ 1440 == 1 ? '' : 's'}',
      _ when minutes % 60 == 0 => 'Starts in ${minutes ~/ 60} hour'
          '${minutes ~/ 60 == 1 ? '' : 's'}',
      _ => 'Starts in $minutes min',
    };
    final location = event.location;
    return location == null || location.isEmpty ? when : '$when · $location';
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => isAndroidDevice
      ? NotificationReminderScheduler(
          NotificationService.instance,
          ref.watch(clockProvider),
        )
      : const NoopReminderScheduler(),
);
