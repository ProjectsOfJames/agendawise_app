import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native helpers that decide how a ringing alarm reaches the screen.
class AlarmDisplay {
  const AlarmDisplay();

  static const _channel = MethodChannel('agendawise/alarm_display');

  /// False on Android 14+ when "full-screen notifications" are not allowed;
  /// the alarm then only shows as a notification on the lock screen.
  Future<bool> canUseFullScreenIntent() async {
    try {
      return await _channel.invokeMethod<bool>('canUseFullScreenIntent') ?? true;
    } on Object catch (error) {
      debugPrint('Full-screen check failed: $error');
      return true;
    }
  }

  Future<void> openFullScreenIntentSettings() =>
      _call('openFullScreenIntentSettings');

  /// Opens the app at [at] if the phone is unlocked then. Needs the
  /// "Display over other apps" permission to have any effect.
  Future<void> scheduleLaunch(int id, DateTime at) =>
      _call('scheduleLaunch', {'id': id, 'at': at.millisecondsSinceEpoch});

  Future<void> cancelLaunch(int id) => _call('cancelLaunch', {'id': id});

  /// Current alarm volume step, or null when it cannot be read.
  Future<int?> alarmVolumeLevel() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, int>('getAlarmVolume');
      return result?['level'];
    } on Object catch (error) {
      debugPrint('getAlarmVolume failed: $error');
      return null;
    }
  }

  Future<void> setAlarmVolumeLevel(int level) =>
      _call('setAlarmVolume', {'level': level});

  Future<void> _call(String method, [Map<String, Object>? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on Object catch (error) {
      debugPrint('$method failed: $error');
    }
  }
}
