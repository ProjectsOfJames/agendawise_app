import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/alarms_dao.dart';
import '../../difficulty/data/interaction_logger.dart';
import '../data/alarm_repository.dart';
import '../domain/alarm_rules.dart';
import 'alarm_scheduler.dart';

/// Snooze and dismiss for an alarm that is ringing.
///
/// The snooze count belongs to one ringing session: it travels with the
/// rescheduled ring and is dropped when the alarm is dismissed.
class RingingController {
  RingingController(
    this._alarms,
    this._scheduler,
    this._playback,
    this._logger,
  );

  final AlarmRepository _alarms;
  final AlarmScheduler _scheduler;
  final AlarmPlayback _playback;
  final InteractionLogger _logger;

  Future<AlarmWithChallenge?> load(String alarmId) => _alarms.getById(alarmId);

  /// Returns false when the snooze limit has been reached.
  Future<bool> snooze(Alarm alarm, {required int snoozesUsed}) async {
    if (!canSnooze(limit: alarm.snoozeLimit, used: snoozesUsed)) return false;
    await _playback.snooze(
      alarm,
      snoozesUsed: snoozesUsed + 1,
      delay: Duration(minutes: alarm.snoozeMinutes),
    );
    await _logger.alarmSnoozed(alarm.id);
    return true;
  }

  /// Stops the alarm. A repeating alarm is scheduled for its next day; a
  /// one-off alarm is switched off.
  Future<void> dismiss(Alarm alarm) async {
    await _playback.stop(alarm.id);
    await _logger.alarmDismissed(alarm.id);
    if (alarm.repeatDays != 0) {
      await _scheduler.schedule(alarm);
    } else {
      await _alarms.setActive(alarm.id, false);
    }
  }

  /// Silences a ring whose alarm record no longer exists.
  Future<void> stopOrphan(String alarmId) => _playback.stop(alarmId);
}

final ringingControllerProvider = Provider<RingingController>(
  (ref) => RingingController(
    ref.watch(alarmRepositoryProvider),
    ref.watch(alarmSchedulerProvider),
    ref.watch(alarmPlaybackProvider),
    ref.watch(interactionLoggerProvider),
  ),
);
