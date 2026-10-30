import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/settings/data/settings_repository.dart';
import '../../shared/widgets/permission_dialog.dart';
import 'alarm_display.dart';
import 'platform_support.dart';

const _batteryPromptShownKey = 'battery_prompt_shown';
const _overlayPromptShownKey = 'overlay_prompt_shown';

/// Asks for the Android permissions a feature needs, each preceded by an
/// explanation, at the moment the feature is used. Declining never blocks
/// saving; the feature then works with reduced reliability.
class PermissionGate {
  PermissionGate(this._settings, [this._display = const AlarmDisplay()]);

  final SettingsRepository _settings;
  final AlarmDisplay _display;

  /// Notifications (to show the ringing alarm) and exact alarms.
  Future<void> ensureForAlarms(BuildContext context) async {
    if (!isAndroidDevice) return;
    await _ensureNotifications(
      context,
      'Alarms show a notification while they ring, which lets them appear '
      'over the lock screen.',
    );
    if (!context.mounted) return;
    await _ensureExactAlarms(
      context,
      'AgendaWise needs permission to ring at the exact time you set. '
      'Without it, alarms may arrive late.',
    );
    if (!context.mounted) return;
    await _ensureFullScreen(context);
    if (!context.mounted) return;
    await _offerOverlay(context);
  }

  /// Android 14+ may block full-screen notifications; without them a
  /// ringing alarm on a locked phone only shows as a notification.
  Future<void> _ensureFullScreen(BuildContext context) async {
    if (await _display.canUseFullScreenIntent()) return;
    if (!context.mounted) return;
    final proceed = await showPermissionExplanation(
      context,
      icon: Icons.fullscreen_rounded,
      title: 'Show alarms full screen',
      message: 'This lets a ringing alarm fill the screen when your phone is '
          'locked, instead of showing only a notification.',
      acceptLabel: 'Open settings',
    );
    if (proceed) await _display.openFullScreenIntentSettings();
  }

  /// Offered once: lets the ringing screen open straight away while the
  /// phone is unlocked and in use, where Android otherwise shows a pop-up
  /// notification.
  Future<void> _offerOverlay(BuildContext context) async {
    if (await Permission.systemAlertWindow.isGranted) return;
    if (await _settings.getBool(_overlayPromptShownKey) ?? false) return;
    await _settings.setBool(_overlayPromptShownKey, true);
    if (!context.mounted) return;
    final proceed = await showPermissionExplanation(
      context,
      icon: Icons.open_in_new_rounded,
      title: 'Open alarms over other apps',
      message: 'While you are using your phone, Android shows a ringing alarm '
          'as a small pop-up. Allow AgendaWise to display over other apps so '
          'the alarm screen opens straight away.',
      declineLabel: 'Later',
      acceptLabel: 'Open settings',
    );
    if (proceed) await Permission.systemAlertWindow.request();
  }

  /// Notifications and exact timing for event reminders.
  Future<void> ensureForReminders(BuildContext context) async {
    if (!isAndroidDevice) return;
    await _ensureNotifications(
      context,
      'Event reminders arrive as notifications. Without this permission '
      'they cannot be shown.',
    );
    if (!context.mounted) return;
    await _ensureExactAlarms(
      context,
      'This lets reminders arrive at the exact time. Without it, Android '
      'may deliver them a few minutes late.',
    );
  }

  /// Microphone access for voice input. Returns true when it is granted.
  Future<bool> ensureForMicrophone(BuildContext context) async {
    if (!isAndroidDevice) return false;
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    if (!context.mounted) return false;
    if (status.isPermanentlyDenied) {
      final proceed = await showPermissionExplanation(
        context,
        icon: Icons.mic_off_outlined,
        title: 'Microphone is off',
        message: 'Voice input needs the microphone. Turn it on in the app '
            'settings, then try again.',
        acceptLabel: 'Open settings',
      );
      if (proceed) await openAppSettings();
      return false;
    }
    final proceed = await showPermissionExplanation(
      context,
      icon: Icons.mic_none_rounded,
      title: 'Allow the microphone',
      message: 'AgendaWise listens only while the voice screen is open, and '
          'turns what you say into a task, alarm or event for you to check.',
    );
    if (!proceed) return false;
    return (await Permission.microphone.request()).isGranted;
  }

  /// Shown once, after an alarm is saved, if the app is still subject to
  /// battery optimisation.
  Future<void> offerBatteryExemption(BuildContext context) async {
    if (!isAndroidDevice) return;
    if (await _settings.getBool(_batteryPromptShownKey) ?? false) return;
    if (await Permission.ignoreBatteryOptimizations.isGranted) return;
    if (!context.mounted) return;
    await _settings.setBool(_batteryPromptShownKey, true);
    if (!context.mounted) return;
    final proceed = await showPermissionExplanation(
      context,
      icon: Icons.battery_charging_full_rounded,
      title: 'Keep alarms reliable',
      message: 'Some phones stop apps to save battery, which can silence '
          'alarms. Allow AgendaWise to run without restrictions.',
      declineLabel: 'Later',
      acceptLabel: 'Open settings',
    );
    if (proceed) await Permission.ignoreBatteryOptimizations.request();
  }

  Future<void> _ensureNotifications(BuildContext context, String why) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return;
    if (!context.mounted) return;
    if (status.isPermanentlyDenied) {
      await _offerSettings(context, 'Notifications are off', why);
      return;
    }
    final proceed = await showPermissionExplanation(
      context,
      icon: Icons.notifications_none_rounded,
      title: 'Allow notifications',
      message: why,
    );
    if (proceed) await Permission.notification.request();
  }

  Future<void> _ensureExactAlarms(BuildContext context, String why) async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) return;
    if (!context.mounted) return;
    final proceed = await showPermissionExplanation(
      context,
      icon: Icons.alarm_rounded,
      title: 'Allow exact alarms',
      message: why,
    );
    // Opens the system "Alarms & reminders" page on Android 12 and later.
    if (proceed) await Permission.scheduleExactAlarm.request();
  }

  Future<void> _offerSettings(
    BuildContext context,
    String title,
    String why,
  ) async {
    final proceed = await showPermissionExplanation(
      context,
      icon: Icons.notifications_off_outlined,
      title: title,
      message: '$why Turn them on in the app settings.',
      acceptLabel: 'Open settings',
    );
    if (proceed) await openAppSettings();
  }
}

final permissionGateProvider = Provider<PermissionGate>(
  (ref) => PermissionGate(ref.watch(settingsRepositoryProvider)),
);
