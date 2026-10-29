import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'alarm_display.dart';
import 'platform_support.dart';

/// One setting that affects whether alarms ring on time and on screen.
enum ReliabilityItem {
  notifications(
    'Notifications',
    'Needed to show ringing alarms and event reminders',
  ),
  exactAlarms('Exact alarms', 'Rings at the exact minute you set'),
  fullScreen('Full-screen alarms', 'Fills the screen when the phone is locked'),
  overlay(
    'Display over other apps',
    'Opens the alarm screen while you use your phone',
  ),
  battery('No battery restrictions', 'Stops Android from silencing alarms');

  const ReliabilityItem(this.title, this.description);

  final String title;
  final String description;
}

/// Reads and fixes the settings in [ReliabilityItem].
class AlarmReliability {
  const AlarmReliability([this._display = const AlarmDisplay()]);

  final AlarmDisplay _display;

  Future<Map<ReliabilityItem, bool>> check() async {
    if (!isAndroidDevice) {
      return {for (final item in ReliabilityItem.values) item: true};
    }
    return {
      ReliabilityItem.notifications: await Permission.notification.isGranted,
      ReliabilityItem.exactAlarms: await Permission.scheduleExactAlarm.isGranted,
      ReliabilityItem.fullScreen: await _display.canUseFullScreenIntent(),
      ReliabilityItem.overlay: await Permission.systemAlertWindow.isGranted,
      ReliabilityItem.battery:
          await Permission.ignoreBatteryOptimizations.isGranted,
    };
  }

  /// Asks for the permission, or opens the matching system settings page.
  Future<void> fix(ReliabilityItem item) async {
    if (!isAndroidDevice) return;
    switch (item) {
      case ReliabilityItem.notifications:
        final status = await Permission.notification.request();
        if (status.isPermanentlyDenied) await openAppSettings();
      case ReliabilityItem.exactAlarms:
        await Permission.scheduleExactAlarm.request();
      case ReliabilityItem.fullScreen:
        await _display.openFullScreenIntentSettings();
      case ReliabilityItem.overlay:
        await Permission.systemAlertWindow.request();
      case ReliabilityItem.battery:
        await Permission.ignoreBatteryOptimizations.request();
    }
  }
}

final alarmReliabilityProvider =
    Provider<AlarmReliability>((ref) => const AlarmReliability());

/// Current state of each setting; invalidate to re-check.
final reliabilityStatusProvider =
    FutureProvider.autoDispose<Map<ReliabilityItem, bool>>(
  (ref) => ref.watch(alarmReliabilityProvider).check(),
);
