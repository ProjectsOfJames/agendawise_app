import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/daos/alarms_dao.dart';
import '../../../core/platform/permission_gate.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/clock.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../application/alarm_controller.dart';
import '../domain/alarm_days.dart';
import '../domain/alarm_rules.dart';
import 'alarm_form_screen.dart';

const _dayOrder = [
  (DateTime.sunday, 'Su'),
  (DateTime.monday, 'Mo'),
  (DateTime.tuesday, 'Tu'),
  (DateTime.wednesday, 'We'),
  (DateTime.thursday, 'Th'),
  (DateTime.friday, 'Fr'),
  (DateTime.saturday, 'Sa'),
];

class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final alarmsAsync = ref.watch(alarmsListProvider);
    final alarms = alarmsAsync.asData?.value ?? const <AlarmWithChallenge>[];
    final activeCount = alarms.where((a) => a.alarm.isActive).length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const ScreenHeader(label: 'Alarms'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ScreenTitle(
                  eyebrow: 'Active',
                  title: 'Alarms',
                  subtitle: alarms.isEmpty
                      ? null
                      : '$activeCount of ${alarms.length} on',
                ),
              ),
              CircleIconButton(
                icon: Icons.add_rounded,
                semanticLabel: 'Add alarm',
                onPressed: () => context.push(AppRoutes.newAlarm),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (alarmsAsync.hasError)
            Text('Could not load alarms: ${alarmsAsync.error}',
                style: TextStyle(color: c.destructive))
          else if (alarmsAsync.isLoading && alarms.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (alarms.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: PlaceholderNote('No alarms yet. Tap + to add one.'),
            ),
          for (final entry in alarms)
            Padding(
              key: ValueKey(entry.alarm.id),
              padding: const EdgeInsets.only(bottom: 12),
              child: _AlarmCard(entry: entry),
            ),
        ],
      ),
    );
  }
}

class _AlarmCard extends ConsumerWidget {
  const _AlarmCard({required this.entry});

  final AlarmWithChallenge entry;

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(alarmControllerProvider);
    final clock = ref.read(clockProvider);
    if (on) await ref.read(permissionGateProvider).ensureForAlarms(context);
    final next = await controller.setActive(entry.alarm.id, on);
    if (next == null) return;
    final until = next.difference(clock());
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Alarm set ${timeUntilLabel(until)}')));
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(alarmControllerProvider);
    if (await confirmAlarmDelete(context)) {
      await controller.delete(entry.alarm.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final alarm = entry.alarm;
    final active = alarm.isActive;
    final use24 = MediaQuery.alwaysUse24HourFormatOf(context);

    final hour12 = alarm.hour % 12 == 0 ? 12 : alarm.hour % 12;
    final timeText = use24
        ? '${alarm.hour.toString().padLeft(2, '0')}:'
            '${alarm.minute.toString().padLeft(2, '0')}'
        : '$hour12:${alarm.minute.toString().padLeft(2, '0')}';
    final period = alarm.hour < 12 ? 'AM' : 'PM';

    final timeColour = active ? c.foreground : c.mutedForeground;
    final details = [
      if (alarm.repeatDays == 0)
        alarm.ringOn == null
            ? 'Once'
            : MaterialLocalizations.of(context).formatMediumDate(alarm.ringOn!),
      if (entry.challenge != null) challengeName(entry.challenge!.challengeType),
      if (alarm.snoozeLimit != null)
        '${alarm.snoozeLimit} ${alarm.snoozeLimit == 1 ? 'snooze' : 'snoozes'}',
    ].join(' · ');

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: BorderSide(
        color: active ? c.primary.withValues(alpha: 0.25) : c.border,
      ),
    );

    return Opacity(
      opacity: active ? 1 : 0.6,
      child: Material(
        color: c.card,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: () => context.push(AppRoutes.alarm(alarm.id)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            timeText,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 44,
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: timeColour,
                            ),
                          ),
                          if (!use24) ...[
                            const SizedBox(width: 10),
                            Text(
                              period,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: c.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (alarm.title != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          alarm.title!,
                          style: TextStyle(fontSize: 15, color: timeColour),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (final (weekday, short) in _dayOrder)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                short,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      repeatsOnWeekday(alarm.repeatDays, weekday)
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                  color:
                                      repeatsOnWeekday(alarm.repeatDays, weekday)
                                          ? c.primary
                                          : c.mutedForeground,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          details,
                          style:
                              TextStyle(fontSize: 12, color: c.mutedForeground),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Switch(
                      value: active,
                      onChanged: (on) => _toggle(context, ref, on),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        active
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        size: 18,
                        color: active ? c.primary : c.mutedForeground,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _remove(context, ref),
                      style: TextButton.styleFrom(
                        foregroundColor: c.mutedForeground,
                      ),
                      child: const Text('remove'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
