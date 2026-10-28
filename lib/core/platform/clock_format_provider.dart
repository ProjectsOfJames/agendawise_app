import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _channel = MethodChannel('agendawise/device_settings');

/// The device's 24-hour clock setting, read from Android when the app starts
/// and again each time it returns to the foreground, so a change made in the
/// system settings shows without restarting.
///
/// Null until the first answer arrives, or where the platform cannot answer
/// (tests, other platforms); the framework's own value is used then.
class ClockFormatNotifier extends Notifier<bool?> {
  @override
  bool? build() {
    final listener = AppLifecycleListener(onResume: refresh);
    ref.onDispose(listener.dispose);
    refresh();
    return null;
  }

  Future<void> refresh() async {
    try {
      final use24 = await _channel.invokeMethod<bool>('is24HourFormat');
      if (use24 != null) state = use24;
    } on MissingPluginException {
      // No native handler: keep the framework's value.
    } on PlatformException {
      // Lookup failed: keep the last known value.
    }
  }
}

final use24HourFormatProvider =
    NotifierProvider<ClockFormatNotifier, bool?>(ClockFormatNotifier.new);
