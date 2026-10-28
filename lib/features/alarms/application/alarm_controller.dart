import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/alarms_dao.dart';
import '../../../core/errors/validation_exception.dart';
import '../../../core/utils/clock.dart';
import '../data/alarm_repository.dart';
import '../domain/alarm_days.dart';
import '../domain/alarm_rules.dart';
import 'alarm_scheduler.dart';

final alarmsListProvider = StreamProvider<List<AlarmWithChallenge>>(
  (ref) => ref.watch(alarmRepositoryProvider).watchAll(),
);

/// Alarm use cases for the alarm screens.
class AlarmController {
  AlarmController(this._alarms, this._scheduler, this._clock);

  final AlarmRepository _alarms;
  final AlarmScheduler _scheduler;
  final Clock _clock;

  Future<AlarmWithChallenge?> load(String id) => _alarms.getById(id);

  /// Creates the alarm when [id] is null, otherwise updates it.
  /// Returns the next time it rings, or null if it is switched off.
  Future<DateTime?> save(AlarmDraft draft, {String? id}) async {
    final problem = validateAlarm(
      hour: draft.hour,
      minute: draft.minute,
      snoozeMinutes: draft.snoozeMinutes,
      snoozeLimit: draft.snoozeLimit,
    );
    if (problem != null) throw ValidationException(problem);

    final alarmId = id ?? await _alarms.create(draft);
    if (id != null) await _alarms.update(id, draft);
    return _reschedule(alarmId);
  }

  /// Returns the next time it rings, or null when switched off.
  Future<DateTime?> setActive(String id, bool active) async {
    await _alarms.setActive(id, active);
    return _reschedule(id);
  }

  Future<void> delete(String id) async {
    await _scheduler.cancel(id);
    await _alarms.delete(id);
  }

  Future<DateTime?> _reschedule(String id) async {
    final saved = await _alarms.getById(id);
    final alarm = saved?.alarm;
    if (alarm == null || !alarm.isActive) {
      await _scheduler.cancel(id);
      return null;
    }
    await _scheduler.schedule(alarm);
    return nextAlarmTrigger(alarm, _clock());
  }
}

final alarmControllerProvider = Provider<AlarmController>(
  (ref) => AlarmController(
    ref.watch(alarmRepositoryProvider),
    ref.watch(alarmSchedulerProvider),
    ref.watch(clockProvider),
  ),
);
