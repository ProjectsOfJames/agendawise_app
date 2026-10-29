import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/challenge_type.dart';
import '../../../core/errors/validation_exception.dart';
import '../../../core/platform/permission_gate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/clock.dart';
import '../../../shared/widgets/choice_pill.dart';
import '../../../shared/widgets/form_row_card.dart';
import '../../../shared/widgets/form_screen_scaffold.dart';
import '../../../shared/widgets/screen_header.dart';
import '../application/alarm_controller.dart';
import '../data/alarm_repository.dart';
import '../data/alarm_sound_store.dart';
import '../domain/alarm_days.dart';
import '../domain/alarm_rules.dart';
import 'time_wheel.dart';

// Sunday first, matching the calendar.
const _dayOrder = [
  (DateTime.sunday, 'Su'),
  (DateTime.monday, 'Mo'),
  (DateTime.tuesday, 'Tu'),
  (DateTime.wednesday, 'We'),
  (DateTime.thursday, 'Th'),
  (DateTime.friday, 'Fr'),
  (DateTime.saturday, 'Sa'),
];

/// Creates an alarm when [alarmId] is null, otherwise edits that alarm.
class AlarmFormScreen extends ConsumerStatefulWidget {
  const AlarmFormScreen({super.key, this.alarmId});

  final String? alarmId;

  @override
  ConsumerState<AlarmFormScreen> createState() => _AlarmFormScreenState();
}

class _AlarmFormScreenState extends ConsumerState<AlarmFormScreen> {
  final _labelController = TextEditingController();

  late int _hour;
  late int _minute;
  int _repeatDays = 0;
  String _soundRef = alarmTones.keys.first;
  bool _vibrate = true;
  int _snoozeMinutes = 5;
  bool _limitSnoozes = false;
  int _snoozeLimit = 3;
  ChallengeType? _challenge;
  bool _isActive = true;
  DateTime? _ringOn;

  bool _loading = true;
  bool _missing = false;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.alarmId != null;

  @override
  void initState() {
    super.initState();
    // New alarms start on the next full hour.
    final now = ref.read(clockProvider)();
    _hour = (now.hour + 1) % 24;
    _minute = 0;
    _load();
  }

  Future<void> _load() async {
    final id = widget.alarmId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    final saved = await ref.read(alarmControllerProvider).load(id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (saved == null) {
        _missing = true;
        return;
      }
      final alarm = saved.alarm;
      _labelController.text = alarm.title ?? '';
      _hour = alarm.hour;
      _minute = alarm.minute;
      _repeatDays = alarm.repeatDays;
      _soundRef = alarm.soundRef;
      _vibrate = alarm.vibrate;
      _snoozeMinutes = alarm.snoozeMinutes;
      _limitSnoozes = alarm.snoozeLimit != null;
      _snoozeLimit = alarm.snoozeLimit ?? 3;
      _challenge = saved.challenge?.challengeType;
      _isActive = alarm.isActive;
      _ringOn = alarm.ringOn;
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _close() => context.pop();

  void _toggleDay(int weekday) =>
      setState(() => _repeatDays ^= weekdayBit(weekday));

  Future<void> _pickSound() async {
    const fromDevice = '__device__';
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in alarmTones.entries)
              ListTile(
                leading: const Icon(Icons.music_note_outlined),
                title: Text(entry.value),
                trailing: entry.key == _soundRef
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(sheetContext, entry.key),
              ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: Text(AlarmSoundStore.isDeviceSound(_soundRef)
                  ? AlarmSoundStore.displayName(_soundRef)
                  : 'Choose from device'),
              subtitle: AlarmSoundStore.isDeviceSound(_soundRef)
                  ? const Text('Tap to choose another file')
                  : null,
              trailing: AlarmSoundStore.isDeviceSound(_soundRef)
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.pop(sheetContext, fromDevice),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    if (picked != fromDevice) {
      setState(() => _soundRef = picked);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      final chosen = await ref.read(alarmSoundStoreProvider).pickDeviceSound();
      if (chosen != null && mounted) setState(() => _soundRef = chosen);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not use that file: $error')),
      );
    }
  }

  Future<void> _pickCustomSnooze() async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (_) => _NumberDialog(
        title: 'Snooze length',
        suffix: 'minutes',
        initial: _snoozeMinutes,
        min: minSnoozeMinutes,
        max: maxSnoozeMinutes,
      ),
    );
    if (minutes != null && mounted) setState(() => _snoozeMinutes = minutes);
  }

  Future<void> _save() async {
    final problem = validateAlarm(
      hour: _hour,
      minute: _minute,
      snoozeMinutes: _snoozeMinutes,
      snoozeLimit: _limitSnoozes ? _snoozeLimit : null,
    );
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final gate = ref.read(permissionGateProvider);
    await gate.ensureForAlarms(context);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final clock = ref.read(clockProvider);
    try {
      final next = await ref.read(alarmControllerProvider).save(
            AlarmDraft(
              hour: _hour,
              minute: _minute,
              title: _labelController.text,
              repeatDays: _repeatDays,
              snoozeMinutes: _snoozeMinutes,
              snoozeLimit: _limitSnoozes ? _snoozeLimit : null,
              soundRef: _soundRef,
              vibrate: _vibrate,
              // Saving an alarm switches it on.
              isActive: true,
              challengeType: _challenge,
              ringOn: _ringOn,
            ),
            id: widget.alarmId,
          );
      if (next != null) {
        final until = next.difference(clock());
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
              SnackBar(content: Text('Alarm set ${timeUntilLabel(until)}')));
      }
      if (!mounted) return;
      await gate.offerBatteryExemption(context);
      if (mounted) _close();
    } on ValidationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.alarmId;
    if (id == null) return;
    final confirmed = await confirmAlarmDelete(context);
    if (!confirmed) return;
    await ref.read(alarmControllerProvider).delete(id);
    if (mounted) _close();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final title = _isEditing ? 'Edit alarm' : 'New alarm';

    if (_loading || _missing) {
      return FormScreenScaffold(
        title: title,
        onClose: _close,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : Text('This alarm no longer exists.',
                      style: TextStyle(color: c.mutedForeground)),
            ),
          ),
        ],
      );
    }

    final snoozeIsCustom = !snoozeLengthPresets.contains(_snoozeMinutes);

    return FormScreenScaffold(
      title: title,
      onClose: _close,
      bottom: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.destructive)),
          ),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
            child: const Text('Save alarm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        if (_isEditing) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: _saving ? null : _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.destructive,
                side: BorderSide(color: c.destructive),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
              ),
              child: const Text('Delete alarm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
      children: [
        TimeWheel(
          // Rebuilds the wheels if the clock setting changes while open.
          key: ValueKey(MediaQuery.alwaysUse24HourFormatOf(context)),
          hour: _hour,
          minute: _minute,
          use24Hour: MediaQuery.alwaysUse24HourFormatOf(context),
          onChanged: (hour, minute) {
            _hour = hour;
            _minute = minute;
          },
        ),
        if (_isEditing && !_isActive)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'This alarm is off. Saving switches it on.',
              style: TextStyle(fontSize: 12, color: c.mutedForeground),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _labelController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Label (optional)',
            filled: true,
            fillColor: c.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (weekday, short) in _dayOrder)
              ChoicePill(
                label: short,
                selected: repeatsOnWeekday(_repeatDays, weekday),
                onTap: () => _toggleDay(weekday),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _repeatDays != 0
              ? 'Repeats on the selected days.'
              : _ringOn != null
                  ? 'Rings once on '
                      '${MaterialLocalizations.of(context).formatMediumDate(_ringOn!)}.'
                  : 'No days selected: rings once.',
          style: TextStyle(fontSize: 12, color: c.mutedForeground),
        ),
        const SizedBox(height: 12),
        FormRowCard(
          label: 'Sound',
          value: AlarmSoundStore.displayName(_soundRef),
          onTap: _pickSound,
          trailing: Icon(Icons.chevron_right_rounded, color: c.mutedForeground),
        ),
        const SizedBox(height: 10),
        FormRowCard(
          label: 'Vibration',
          onTap: () => setState(() => _vibrate = !_vibrate),
          trailing: Switch(
            value: _vibrate,
            onChanged: (value) => setState(() => _vibrate = value),
          ),
        ),
        const SizedBox(height: 18),
        const SectionLabel('Snooze length (minutes)'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final minutes in snoozeLengthPresets)
              ChoicePill(
                label: '$minutes',
                selected: _snoozeMinutes == minutes,
                onTap: () => setState(() => _snoozeMinutes = minutes),
              ),
            ChoicePill(
              label: snoozeIsCustom ? 'Custom ($_snoozeMinutes)' : 'Custom',
              selected: snoozeIsCustom,
              onTap: _pickCustomSnooze,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FormRowCard(
          label: 'Limit number of snoozes',
          onTap: () => setState(() => _limitSnoozes = !_limitSnoozes),
          trailing: Checkbox(
            value: _limitSnoozes,
            onChanged: (value) =>
                setState(() => _limitSnoozes = value ?? false),
          ),
        ),
        if (_limitSnoozes) ...[
          const SizedBox(height: 10),
          FormRowCard(
            label: 'Allowed snoozes',
            value: '$_snoozeLimit',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Fewer snoozes',
                  onPressed: _snoozeLimit > minSnoozeLimit
                      ? () => setState(() => _snoozeLimit--)
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                IconButton(
                  tooltip: 'More snoozes',
                  onPressed: _snoozeLimit < maxSnoozeLimit
                      ? () => setState(() => _snoozeLimit++)
                      : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        const SectionLabel('Challenge'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in [null, ...ChallengeType.values])
              ChoicePill(
                label: challengeName(type),
                selected: _challenge == type,
                onTap: () => setState(() => _challenge = type),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _challenge == null
              ? 'Stop dismisses the alarm straight away.'
              : 'Stop opens the challenge; the alarm keeps ringing until it '
                  'is solved.',
          style: TextStyle(fontSize: 12, color: c.mutedForeground),
        ),
      ],
    );
  }
}

/// Asks before deleting an alarm. Returns true when confirmed.
Future<bool> confirmAlarmDelete(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete alarm?'),
      content: const Text('It will no longer ring.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            'Delete',
            style: TextStyle(color: AppColors.of(dialogContext).destructive),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    required this.suffix,
    required this.initial,
    required this.min,
    required this.max,
  });

  final String title;
  final String suffix;
  final int initial;
  final int min;
  final int max;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final _controller = TextEditingController(text: '${widget.initial}');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < widget.min || value > widget.max) {
      setState(() => _error = 'Enter ${widget.min} to ${widget.max}');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          suffixText: widget.suffix,
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Set')),
      ],
    );
  }
}
