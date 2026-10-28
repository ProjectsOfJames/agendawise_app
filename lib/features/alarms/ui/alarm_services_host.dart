import 'dart:async';

import 'package:alarm/alarm.dart' as native;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_support.dart';
import '../../../core/router/app_router.dart';
import '../application/schedule_sync.dart';
import '../domain/alarm_ids.dart';

/// Wraps the app to re-sync schedules once at start-up and to open the
/// ringing screen whenever a native alarm starts ringing.
class AlarmServicesHost extends ConsumerStatefulWidget {
  const AlarmServicesHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AlarmServicesHost> createState() => _AlarmServicesHostState();
}

class _AlarmServicesHostState extends ConsumerState<AlarmServicesHost> {
  StreamSubscription<Object>? _ringing;

  /// Ring already shown, as "alarmId:snoozes", so repeated stream events
  /// for the same ring do not open the screen twice.
  String? _shown;

  @override
  void initState() {
    super.initState();
    if (!isAndroidDevice) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scheduleSyncProvider).run();
    });
    _ringing = native.Alarm.ringing.listen((ringingSet) {
      final ringing = ringingSet.alarms;
      if (ringing.isEmpty) {
        _shown = null;
        return;
      }
      final payload = RingPayload.decode(ringing.first.payload);
      if (payload == null) return;
      final key = '${payload.alarmId}:${payload.snoozesUsed}';
      if (key == _shown) return;
      _shown = key;
      ref
          .read(appRouterProvider)
          .push(AppRoutes.ringing(payload.alarmId, payload.snoozesUsed));
    });
  }

  @override
  void dispose() {
    _ringing?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
