import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cloud/activity_actions.dart';
import '../../../core/cloud/activity_logger.dart';
import '../../../core/errors/validation_exception.dart';
import '../../../core/platform/permission_gate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/clock.dart';
import '../../../shared/widgets/choice_pill.dart';
import '../../../shared/widgets/form_row_card.dart';
import '../../../shared/widgets/form_screen_scaffold.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/time_text.dart';
import '../../alarms/application/alarm_controller.dart';
import '../../alarms/data/alarm_repository.dart';
import '../../alarms/domain/alarm_rules.dart';
import '../../calendar/application/event_controller.dart';
import '../../calendar/data/event_repository.dart';
import '../../tasks/application/task_controller.dart';
import '../domain/voice_intent.dart';
import 'voice_widgets.dart';

/// What the confirmation screen opens with. [understood] is false when the
/// user chose the type on the fallback screen.
class VoiceConfirmArgs {
  const VoiceConfirmArgs({required this.intent, required this.understood});

  final VoiceIntent intent;
  final bool understood;
}

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Today", "Tomorrow" or "Fri, 6 Nov".
String friendlyDate(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Today';
  if (day == DateTime(today.year, today.month, today.day + 1)) return 'Tomorrow';
  final text =
      '${_weekdayNames[day.weekday - 1]}, ${day.day} ${_monthNames[day.month - 1]}';
  return day.year == today.year ? text : '$text ${day.year}';
}

/// Every voice result passes through here; nothing is saved until the
/// user confirms.
class VoiceConfirmScreen extends ConsumerStatefulWidget {
  const VoiceConfirmScreen({super.key, required this.args});

  final VoiceConfirmArgs args;

  @override
  ConsumerState<VoiceConfirmScreen> createState() => _VoiceConfirmScreenState();
}

class _VoiceConfirmScreenState extends ConsumerState<VoiceConfirmScreen> {
  late VoiceIntent _intent = widget.args.intent.type == VoiceIntentType.unknown
      ? widget.args.intent.copyWith(type: VoiceIntentType.task)
      : widget.args.intent;
  bool _linkedAlarm = false;
  bool _saving = false;
  String? _error;

  VoiceIntentType get _type => _intent.type;

  DateTime get _now => ref.read(clockProvider)();

  void _setType(VoiceIntentType type) => setState(() {
        _intent = _intent.copyWith(type: type);
        _error = null;
      });

  Future<void> _editTitle() async {
    final controller = TextEditingController(text: _intent.title);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_type == VoiceIntentType.alarm ? 'Alarm label' : 'Title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      setState(() => _intent = _intent.copyWith(title: result.trim()));
    }
  }

  Future<void> _pickDate() async {
    final now = _now;
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _intent.date ?? today,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: DateTime(today.year + 5, 12, 31),
    );
    if (picked != null) {
      setState(() => _intent = _intent.copyWith(date: picked));
    }
  }

  Future<ClockTime?> _askTime(ClockTime? current, ClockTime fallback) async {
    final initial = current ?? fallback;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    return picked == null ? null : ClockTime(picked.hour, picked.minute);
  }

  Future<void> _pickTime() async {
    final picked = await _askTime(_intent.time, const ClockTime(9, 0));
    if (picked != null) setState(() => _intent = _intent.copyWith(time: picked));
  }

  Future<void> _pickEnd() async {
    final start = _intent.time ?? const ClockTime(9, 0);
    final picked =
        await _askTime(_intent.endTime, ClockTime.fromMinutes(start.minutesOfDay + 60));
    if (picked != null) {
      setState(() => _intent = _intent.copyWith(endTime: picked));
    }
  }

  // ---------------------------------------------------------------- save

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final message = switch (_type) {
        VoiceIntentType.alarm => await _saveAlarm(),
        VoiceIntentType.event => await _saveEvent(),
        VoiceIntentType.task || VoiceIntentType.unknown => await _saveTask(),
      };
      if (message == null || !mounted) return;
      ref.read(activityLoggerProvider).log(ActivityAction.voiceUsed, meta: {
        'type': _type.name,
        'understood': widget.args.understood,
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      context.pop();
    } on ValidationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _saveTask() async {
    final title = _intent.title.trim();
    if (title.isEmpty) throw const ValidationException('Add a title first');
    final date = _intent.date;
    final time = _intent.time;
    final now = _now;
    DateTime? dueAt;
    var allDay = false;
    if (date != null && time != null) {
      dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    } else if (date != null) {
      dueAt = DateTime(date.year, date.month, date.day);
      allDay = true;
    } else if (time != null) {
      dueAt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    }
    final linked = _linkedAlarm && dueAt != null && !allDay;
    if (linked) {
      await ref.read(permissionGateProvider).ensureForAlarms(context);
      if (!mounted) return null;
    }
    await ref.read(taskControllerProvider).save(TaskForm(
          title: title,
          dueAt: dueAt,
          isAllDay: allDay,
          linkedAlarm: linked,
        ));
    return 'Task added.';
  }

  Future<String?> _saveAlarm() async {
    final time = _intent.time;
    if (time == null) throw const ValidationException('Choose a time first');
    final gate = ref.read(permissionGateProvider);
    await gate.ensureForAlarms(context);
    if (!mounted) return null;
    final title = _intent.title.trim();
    final next = await ref.read(alarmControllerProvider).save(AlarmDraft(
          hour: time.hour,
          minute: time.minute,
          title: title.isEmpty ? null : title,
          ringOn: _intent.date,
        ));
    if (mounted) await gate.offerBatteryExemption(context);
    if (next == null) return 'Alarm saved, but that time has already passed.';
    return 'Alarm set ${timeUntilLabel(next.difference(_now))}';
  }

  Future<String?> _saveEvent() async {
    final title = _intent.title.trim();
    if (title.isEmpty) throw const ValidationException('Add a title first');
    await ref.read(permissionGateProvider).ensureForReminders(context);
    if (!mounted) return null;
    final now = _now;
    final date = _intent.date ?? DateTime(now.year, now.month, now.day);
    final start = _intent.time;
    final startMinutes = start?.minutesOfDay ?? 9 * 60;
    final endMinutes = _intent.endTime?.minutesOfDay ??
        ClockTime.fromMinutes(startMinutes + 60).minutesOfDay;
    await ref.read(eventControllerProvider).save(EventForm(
          date: date,
          title: title,
          isAllDay: start == null,
          startMinutes: startMinutes,
          endMinutes: endMinutes,
          colourHex: defaultEventColour,
        ));
    return 'Event added.';
  }

  // ------------------------------------------------------------------ ui

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final now = ref.watch(clockProvider)();
    final date = _intent.date;
    final time = _intent.time;
    final end = _intent.endTime;
    final heard = _intent.heard.trim();
    final canLink = time != null;

    String timeText(ClockTime? value, String empty) => value == null
        ? empty
        : formatTime(context, DateTime(2000, 1, 1, value.hour, value.minute));

    Widget clearButton(VoidCallback onPressed, String label) => IconButton(
          tooltip: label,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close_rounded, size: 18, color: c.mutedForeground),
          onPressed: onPressed,
        );

    final titleLabel = _intent.title.isEmpty
        ? (_type == VoiceIntentType.alarm ? 'No label' : 'Add a title')
        : _intent.title;

    return FormScreenScaffold(
      title: 'Confirm voice input',
      onClose: () => context.pop(),
      bottom: [
        if (_error != null) ...[
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.destructive)),
          const SizedBox(height: 8),
        ],
        VoicePrimaryButton(label: 'Save', busy: _saving, onPressed: _save),
        const SizedBox(height: 10),
        VoiceOutlinedButton(
          label: 'Cancel',
          onPressed: _saving ? null : () => context.pop(),
        ),
        const SizedBox(height: 8),
        Text(
          'Nothing is saved until you confirm.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: c.mutedForeground),
        ),
      ],
      children: [
        if (heard.isNotEmpty) ...[
          HeardCard(
            caption: 'Heard',
            child: Text(heard,
                style: TextStyle(fontSize: 15, color: c.foreground)),
          ),
          const SizedBox(height: 16),
        ],
        const SectionLabel('Detected type'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final type in const [
              VoiceIntentType.task,
              VoiceIntentType.alarm,
              VoiceIntentType.event,
            ])
              ChoicePill(
                label: type.label,
                selected: _type == type,
                onTap: () => _setType(type),
              ),
          ],
        ),
        const SizedBox(height: 14),
        VoiceTitleRow(
          title: titleLabel,
          placeholder: _intent.title.isEmpty,
          onEdit: _editTitle,
        ),
        const SizedBox(height: 10),
        FormRowCard(
          label: 'Date',
          value: date == null
              ? (_type == VoiceIntentType.event
                  ? 'Today'
                  : _type == VoiceIntentType.alarm
                      ? 'Next time it comes round'
                      : 'None')
              : friendlyDate(date, now),
          onTap: _pickDate,
          trailing: date == null
              ? null
              : clearButton(
                  () => setState(() => _intent = _intent.copyWith(clearDate: true)),
                  'Clear date',
                ),
        ),
        const SizedBox(height: 10),
        FormRowCard(
          label: _type == VoiceIntentType.event ? 'Starts' : 'Time',
          value: timeText(
            time,
            switch (_type) {
              VoiceIntentType.alarm => 'Choose',
              VoiceIntentType.event => 'All day',
              _ => 'None',
            },
          ),
          onTap: _pickTime,
          trailing: time == null || _type == VoiceIntentType.alarm
              ? null
              : clearButton(
                  () => setState(() => _intent =
                      _intent.copyWith(clearTime: true, clearEndTime: true)),
                  'Clear time',
                ),
        ),
        if (_type == VoiceIntentType.event && time != null) ...[
          const SizedBox(height: 10),
          FormRowCard(
            label: 'Ends',
            value: timeText(
              end,
              timeText(ClockTime.fromMinutes(time.minutesOfDay + 60), ''),
            ),
            onTap: _pickEnd,
          ),
        ],
        if (_type == VoiceIntentType.task) ...[
          const SizedBox(height: 10),
          FormRowCard(
            label: 'Also create a linked alarm',
            onTap: canLink
                ? () => setState(() => _linkedAlarm = !_linkedAlarm)
                : null,
            trailing: Checkbox(
              value: canLink && _linkedAlarm,
              onChanged: canLink
                  ? (value) => setState(() => _linkedAlarm = value ?? false)
                  : null,
            ),
          ),
          if (!canLink)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Add a time to create a linked alarm.',
                style: TextStyle(fontSize: 12, color: c.mutedForeground),
              ),
            ),
        ],
      ],
    );
  }
}
