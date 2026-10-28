import 'package:alarm/alarm.dart' as native;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/platform/alarm_display.dart';
import '../../../core/platform/platform_support.dart';
import '../../../core/utils/clock.dart';
import '../data/alarm_sound_store.dart';
import '../domain/alarm_days.dart';
import '../domain/alarm_ids.dart';

/// Registers alarms with the system so they ring at their next trigger.
abstract interface class AlarmScheduler {
  /// Replaces any schedule already registered for [alarm].
  Future<void> schedule(Alarm alarm);

  Future<void> cancel(String alarmId);
}

/// Controls an alarm that is ringing now.
abstract interface class AlarmPlayback {
  /// Silences the alarm without scheduling anything.
  Future<void> stop(String alarmId);

  /// Silences the alarm and rings it again after [delay], carrying the
  /// number of snoozes used so far.
  Future<void> snooze(Alarm alarm, {required int snoozesUsed, required Duration delay});
}

/// Used in tests and on platforms without the native alarm service.
class NoopAlarmScheduler implements AlarmScheduler, AlarmPlayback {
  const NoopAlarmScheduler();

  @override
  Future<void> schedule(Alarm alarm) async {}

  @override
  Future<void> cancel(String alarmId) async {}

  @override
  Future<void> stop(String alarmId) async {}

  @override
  Future<void> snooze(
    Alarm alarm, {
    required int snoozesUsed,
    required Duration delay,
  }) async {}
}

/// Schedules and rings alarms through the `alarm` package.
class NativeAlarmScheduler implements AlarmScheduler, AlarmPlayback {
  NativeAlarmScheduler(this._clock, [this._display = const AlarmDisplay()]);

  final Clock _clock;
  final AlarmDisplay _display;

  @override
  Future<void> schedule(Alarm alarm) => _schedule(alarm, keepPendingSnooze: false);

  /// Like [schedule], but leaves a snoozed ring in place; used when
  /// re-registering alarms at start-up.
  Future<void> resync(Alarm alarm) => _schedule(alarm, keepPendingSnooze: true);

  Future<void> _schedule(Alarm alarm, {required bool keepPendingSnooze}) async {
    final next = nextAlarmTrigger(alarm, _clock());
    if (next == null) {
      await cancel(alarm.id);
      return;
    }
    final id = nativeIdFor(alarm.id);
    if (keepPendingSnooze) {
      if (await native.Alarm.isRinging(id)) return;
      final existing = await native.Alarm.getAlarm(id);
      final payload = RingPayload.decode(existing?.payload);
      if (existing != null &&
          payload != null &&
          payload.snoozesUsed > 0 &&
          existing.dateTime.isAfter(_clock())) {
        return;
      }
    }
    await _set(alarm, next, RingPayload(alarmId: alarm.id));
  }

  @override
  Future<void> cancel(String alarmId) async {
    final id = nativeIdFor(alarmId);
    await _display.cancelLaunch(id);
    try {
      await native.Alarm.stop(id);
    } on Object catch (error) {
      debugPrint('Could not cancel alarm $alarmId: $error');
    }
  }

  @override
  Future<void> stop(String alarmId) => cancel(alarmId);

  @override
  Future<void> snooze(
    Alarm alarm, {
    required int snoozesUsed,
    required Duration delay,
  }) async {
    await cancel(alarm.id);
    await _set(
      alarm,
      _clock().add(delay),
      RingPayload(alarmId: alarm.id, snoozesUsed: snoozesUsed),
    );
  }

  /// Ids of stored alarms the native side still has scheduled.
  Future<Map<int, RingPayload?>> scheduledNative() async {
    final alarms = await native.Alarm.getAlarms();
    return {for (final a in alarms) a.id: RingPayload.decode(a.payload)};
  }

  Future<void> stopNative(int nativeId) async {
    await _display.cancelLaunch(nativeId);
    try {
      await native.Alarm.stop(nativeId);
    } on Object catch (error) {
      debugPrint('Could not stop native alarm $nativeId: $error');
    }
  }

  Future<void> _set(Alarm alarm, DateTime at, RingPayload payload) async {
    final label = alarm.title;
    final settings = native.AlarmSettings(
      id: nativeIdFor(alarm.id),
      dateTime: at,
      assetAudioPath: AlarmSoundStore.audioPathFor(alarm.soundRef),
      loopAudio: true,
      vibrate: alarm.vibrate,
      // Not const: the constructor's assertion cannot run at compile time.
      volumeSettings: native.VolumeSettings.fade(
        fadeDuration: const Duration(seconds: 5),
      ),
      notificationSettings: native.NotificationSettings(
        title: label == null || label.isEmpty ? 'Alarm' : label,
        body: 'Open AgendaWise to stop or snooze the alarm.',
        // No stop button and no stop-on-swipe: the alarm is only silenced
        // from the ringing screen, where snooze limits and challenges apply.
        androidStopAlarmOnDismiss: false,
      ),
      androidFullScreenIntent: true,
      warningNotificationOnKill: true,
      androidStopAlarmOnTermination: false,
      payload: payload.encode(),
    );
    try {
      await native.Alarm.set(alarmSettings: settings);
      await _display.scheduleLaunch(settings.id, at);
    } on Object catch (error) {
      debugPrint('Could not schedule alarm ${alarm.id}: $error');
    }
  }
}

final _nativeSchedulerProvider = Provider<NativeAlarmScheduler>(
  (ref) => NativeAlarmScheduler(ref.watch(clockProvider)),
);

/// Native scheduler on Android, a no-op elsewhere (including tests).
final alarmSchedulerProvider = Provider<AlarmScheduler>(
  (ref) => isAndroidDevice
      ? ref.watch(_nativeSchedulerProvider)
      : const NoopAlarmScheduler(),
);

final alarmPlaybackProvider = Provider<AlarmPlayback>(
  (ref) => isAndroidDevice
      ? ref.watch(_nativeSchedulerProvider)
      : const NoopAlarmScheduler(),
);

/// Null off Android.
final nativeAlarmSchedulerProvider = Provider<NativeAlarmScheduler?>(
  (ref) => isAndroidDevice ? ref.watch(_nativeSchedulerProvider) : null,
);
