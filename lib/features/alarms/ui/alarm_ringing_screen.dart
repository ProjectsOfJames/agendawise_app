import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/screen_header.dart';
import '../application/ringing_controller.dart';
import '../domain/alarm_rules.dart';

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

/// Full-screen view of a ringing alarm. It has no close control and the
/// back action is blocked: the alarm ends only through Snooze or Stop.
class AlarmRingingScreen extends ConsumerStatefulWidget {
  const AlarmRingingScreen({
    super.key,
    required this.alarmId,
    this.snoozesUsed = 0,
  });

  final String alarmId;
  final int snoozesUsed;

  @override
  ConsumerState<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends ConsumerState<AlarmRingingScreen> {
  Alarm? _alarm;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await ref.read(ringingControllerProvider).load(widget.alarmId);
    if (!mounted) return;
    setState(() {
      _alarm = saved?.alarm;
      _loading = false;
    });
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.alarms);
    }
  }

  Future<void> _snooze(Alarm alarm) async {
    setState(() => _busy = true);
    final snoozed = await ref
        .read(ringingControllerProvider)
        .snooze(alarm, snoozesUsed: widget.snoozesUsed);
    if (!mounted) return;
    if (snoozed) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Snoozed for ${alarm.snoozeMinutes} minutes'),
      ));
      _leave();
    } else {
      setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    setState(() => _busy = true);
    final controller = ref.read(ringingControllerProvider);
    final alarm = _alarm;
    if (alarm == null) {
      await controller.stopOrphan(widget.alarmId);
    } else {
      await controller.dismiss(alarm);
    }
    if (mounted) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final alarm = _alarm;
    final now = DateTime.now();
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);

    final hour = alarm?.hour ?? now.hour;
    final minute = alarm?.minute ?? now.minute;
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final time = use24
        ? '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'
        : '$hour12:${minute.toString().padLeft(2, '0')}';
    final subtitle = [
      if (!use24) hour < 12 ? 'AM' : 'PM',
      _weekdays[now.weekday - 1],
    ].join(' · ');

    final limit = alarm?.snoozeLimit;
    final used = widget.snoozesUsed;
    final snoozeAllowed =
        alarm != null && canSnooze(limit: limit, used: used);
    final String? countLabel = limit != null
        ? 'Snooze $used of $limit'
        : used > 0
            ? 'Snoozed $used ${used == 1 ? 'time' : 'times'}'
            : null;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionLabel('Alarm'),
                const Spacer(flex: 2),
                Text(
                  time,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 88,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: c.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: c.mutedForeground),
                ),
                const SizedBox(height: 16),
                if (!_loading)
                  Text(
                    alarm?.title ?? 'Alarm',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: c.foreground,
                    ),
                  ),
                if (countLabel != null) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                            color: c.primary.withValues(alpha: 0.45)),
                      ),
                      child: Text(countLabel,
                          style: TextStyle(color: c.foreground)),
                    ),
                  ),
                ],
                const Spacer(flex: 3),
                if (snoozeAllowed) ...[
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _snooze(alarm),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.foreground,
                        side: BorderSide(
                            color: c.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                      ),
                      child: Text(
                        'Snooze ${alarm.snoozeMinutes} minutes',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _busy || _loading ? null : _stop,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                    ),
                    child: const Text(
                      'Stop',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
