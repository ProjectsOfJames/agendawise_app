import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/application/reminder_scheduler.dart';
import '../../challenges/application/challenge_volume.dart';
import '../../calendar/data/event_repository.dart';
import '../data/alarm_repository.dart';
import 'alarm_scheduler.dart';

/// Re-registers every active alarm and every event reminder with the
/// system, and removes native alarms whose record is gone or switched off.
/// Run at start-up so schedules recover from restarts, updates and time
/// changes, and so repeating reminders move on to their next occurrence.
class ScheduleSync {
  ScheduleSync(this._ref);

  final Ref _ref;

  Future<void> run() async {
    await _ref.read(challengeVolumeProvider).restoreLeftover();
    await _syncAlarms();
    await _syncReminders();
  }

  Future<void> _syncAlarms() async {
    final scheduler = _ref.read(nativeAlarmSchedulerProvider);
    if (scheduler == null) return;
    try {
      final active = await _ref.read(alarmRepositoryProvider).getActive();
      final activeIds = {for (final alarm in active) alarm.id};
      for (final alarm in active) {
        await scheduler.resync(alarm);
      }
      final native = await scheduler.scheduledNative();
      for (final entry in native.entries) {
        final alarmId = entry.value?.alarmId;
        if (alarmId == null || !activeIds.contains(alarmId)) {
          await scheduler.stopNative(entry.key);
        }
      }
    } on Object catch (error) {
      debugPrint('Alarm sync failed: $error');
    }
  }

  Future<void> _syncReminders() async {
    final reminders = _ref.read(reminderSchedulerProvider);
    if (reminders is! NotificationReminderScheduler) return;
    try {
      final events = await _ref.read(eventRepositoryProvider).getWithReminders();
      for (final event in events) {
        await reminders.schedule(event);
      }
    } on Object catch (error) {
      debugPrint('Reminder sync failed: $error');
    }
  }
}

final scheduleSyncProvider = Provider<ScheduleSync>(ScheduleSync.new);
