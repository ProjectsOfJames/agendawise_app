import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/validation_exception.dart';
import '../../../core/platform/permission_gate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/colour_hex.dart';
import '../../../core/utils/date_labels.dart';
import '../../../shared/widgets/choice_pill.dart';
import '../../../shared/widgets/form_row_card.dart';
import '../../../shared/widgets/form_screen_scaffold.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/time_text.dart';
import '../application/event_controller.dart';
import '../domain/repeat_rule.dart';

const _presetColours = [
  '#8B5CF6',
  '#F97316',
  '#F43F5E',
  '#06B6D4',
  '#34D399',
  '#FACC15',
];

const _reminderPresets = <int, String>{
  0: 'At event time',
  10: '10 min before',
  60: '1 hour before',
  1440: '1 day before',
};

const _unitNames = {
  RepeatUnit.days: ('Days', 'day', 'days'),
  RepeatUnit.weeks: ('Weeks', 'week', 'weeks'),
  RepeatUnit.months: ('Months', 'month', 'months'),
  RepeatUnit.years: ('Years', 'year', 'years'),
};

/// Creates an event when [eventId] is null, otherwise edits that event.
class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.eventId, this.initialDate});

  final String? eventId;

  /// Preselected date for a new event; today when null.
  final DateTime? initialDate;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();

  late DateTime _date;
  bool _isAllDay = false;
  int _startMinutes = 9 * 60;
  int _endMinutes = 10 * 60;
  int? _reminder = 10;
  RepeatUnit? _repeatUnit;
  int _repeatInterval = 1;
  String _colour = _presetColours.first;
  List<String> _customColours = const [];

  bool _loading = true;
  bool _missing = false;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    _date = dateOnly(widget.initialDate ?? ref.read(clockProvider)());
    _load();
  }

  Future<void> _load() async {
    final controller = ref.read(eventControllerProvider);
    final custom = await controller.customColours();
    final id = widget.eventId;
    final event = id == null ? null : await controller.load(id);
    if (!mounted) return;
    setState(() {
      _customColours = custom;
      _loading = false;
      if (id == null) return;
      if (event == null) {
        _missing = true;
        return;
      }
      final form = EventForm.fromEvent(event);
      _titleController.text = form.title;
      _locationController.text = form.location;
      _date = dateOnly(form.date);
      _isAllDay = form.isAllDay;
      _startMinutes = form.startMinutes;
      _endMinutes = form.endMinutes;
      _reminder = form.reminderMinutesBefore;
      _repeatUnit = form.repeat?.unit;
      _repeatInterval = form.repeat?.interval ?? 1;
      _colour = form.colourHex.toUpperCase();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _close() => context.pop();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 5),
      lastDate: DateTime(_date.year + 10),
    );
    if (picked != null && mounted) setState(() => _date = dateOnly(picked));
  }

  Future<void> _pickTime({required bool start}) async {
    final minutes = start ? _startMinutes : _endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null || !mounted) return;
    final value = picked.hour * 60 + picked.minute;
    setState(() {
      _error = null;
      if (start) {
        // Keep the event's length when the start moves.
        final length = _endMinutes - _startMinutes;
        _startMinutes = value;
        _endMinutes = (value + (length > 0 ? length : 60)).clamp(0, 24 * 60 - 1);
      } else {
        _endMinutes = value;
      }
    });
  }

  Future<void> _pickCustomReminder() async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (_) => _CustomReminderDialog(initialMinutes: _reminder ?? 30),
    );
    if (minutes != null && mounted) setState(() => _reminder = minutes);
  }

  Future<void> _pickCustomColour() async {
    final colour = await showDialog<Color>(
      context: context,
      builder: (_) => _HuePickerDialog(initial: ColourHex.decode(_colour)),
    );
    if (colour == null || !mounted) return;
    final hex = ColourHex.encode(colour);
    final saved = await ref.read(eventControllerProvider).addCustomColour(hex);
    if (!mounted) return;
    setState(() {
      _colour = hex;
      _customColours = saved;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    if (_reminder != null) {
      await ref.read(permissionGateProvider).ensureForReminders(context);
      if (!mounted) return;
    }
    final unit = _repeatUnit;
    try {
      await ref.read(eventControllerProvider).save(
            EventForm(
              date: _date,
              title: _titleController.text,
              isAllDay: _isAllDay,
              startMinutes: _startMinutes,
              endMinutes: _endMinutes,
              location: _locationController.text,
              reminderMinutesBefore: _reminder,
              repeat: unit == null ? null : RepeatRule(unit, _repeatInterval),
              colourHex: _colour,
            ),
            id: widget.eventId,
          );
      if (mounted) _close();
    } on ValidationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.eventId;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete event?'),
        content: const Text(
            'A task linked to this event is kept and only loses the link.'),
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
    if (confirmed != true) return;
    await ref.read(eventControllerProvider).delete(id);
    if (mounted) _close();
  }

  String _dateLabel(DateTime date) =>
      MaterialLocalizations.of(context).formatMediumDate(date);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final title = _isEditing ? 'Edit event' : 'New event';

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
                  : Text('This event no longer exists.',
                      style: TextStyle(color: c.mutedForeground)),
            ),
          ),
        ],
      );
    }

    final reminderIsCustom =
        _reminder != null && !_reminderPresets.containsKey(_reminder);
    final colours = [
      ..._presetColours,
      ..._customColours.where((hex) => !_presetColours.contains(hex.toUpperCase())),
      if (!_presetColours.contains(_colour) &&
          !_customColours.map((h) => h.toUpperCase()).contains(_colour))
        _colour,
    ];

    final fieldDecoration = InputDecoration(
      filled: true,
      fillColor: c.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: BorderSide.none,
      ),
    );

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
            child: const Text('Save event',
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
              child: const Text('Delete event',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
      children: [
        TextField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          decoration: fieldDecoration.copyWith(
              hintText: 'Title (default: My event)'),
        ),
        const SizedBox(height: 10),
        FormRowCard(
          label: 'Date',
          value: _dateLabel(_date),
          onTap: _pickDate,
        ),
        const SizedBox(height: 10),
        FormRowCard(
          label: 'All day',
          onTap: () => setState(() => _isAllDay = !_isAllDay),
          trailing: Switch(
            value: _isAllDay,
            onChanged: (value) => setState(() => _isAllDay = value),
          ),
        ),
        if (!_isAllDay) ...[
          const SizedBox(height: 10),
          FormRowCard(
            label: 'Starts',
            value: formatMinutes(context, _startMinutes),
            onTap: () => _pickTime(start: true),
          ),
          const SizedBox(height: 10),
          FormRowCard(
            label: 'Ends',
            value: formatMinutes(context, _endMinutes),
            onTap: () => _pickTime(start: false),
          ),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: _locationController,
          textCapitalization: TextCapitalization.sentences,
          decoration: fieldDecoration.copyWith(hintText: 'Location (optional)'),
        ),
        const SizedBox(height: 18),
        const SectionLabel('Notify me'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in _reminderPresets.entries)
              ChoicePill(
                label: entry.value,
                selected: _reminder == entry.key,
                onTap: () => setState(() => _reminder = entry.key),
              ),
            ChoicePill(
              label: reminderIsCustom
                  ? 'Custom (${_reminderLabel(_reminder!)})'
                  : 'Custom',
              selected: reminderIsCustom,
              onTap: _pickCustomReminder,
            ),
            ChoicePill(
              label: 'None',
              selected: _reminder == null,
              onTap: () => setState(() => _reminder = null),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionLabel('Repeat'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoicePill(
              label: 'Never',
              selected: _repeatUnit == null,
              onTap: () => setState(() => _repeatUnit = null),
            ),
            for (final unit in RepeatUnit.values)
              ChoicePill(
                label: _unitNames[unit]!.$1,
                selected: _repeatUnit == unit,
                onTap: () => setState(() => _repeatUnit = unit),
              ),
          ],
        ),
        if (_repeatUnit != null) ...[
          const SizedBox(height: 10),
          FormRowCard(
            label: 'Every',
            value: '$_repeatInterval '
                '${_repeatInterval == 1 ? _unitNames[_repeatUnit]!.$2 : _unitNames[_repeatUnit]!.$3}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Fewer',
                  onPressed: _repeatInterval > 1
                      ? () => setState(() => _repeatInterval--)
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                IconButton(
                  tooltip: 'More',
                  onPressed: _repeatInterval < 99
                      ? () => setState(() => _repeatInterval++)
                      : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        const SectionLabel('Colour'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final hex in colours)
              _ColourDot(
                colour: ColourHex.decode(hex),
                selected: hex.toUpperCase() == _colour.toUpperCase(),
                onTap: () => setState(() => _colour = hex.toUpperCase()),
              ),
            const SizedBox(width: 4),
            ChoicePill(
              label: 'Custom',
              leading: Icons.add_rounded,
              selected: false,
              onTap: _pickCustomColour,
            ),
          ],
        ),
      ],
    );
  }
}

String _reminderLabel(int minutes) {
  if (minutes % 1440 == 0) {
    final days = minutes ~/ 1440;
    return '$days ${days == 1 ? 'day' : 'days'}';
  }
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return '$hours ${hours == 1 ? 'hour' : 'hours'}';
  }
  return '$minutes min';
}

class _ColourDot extends StatelessWidget {
  const _ColourDot({
    required this.colour,
    required this.selected,
    required this.onTap,
  });

  final Color colour;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Colour ${ColourHex.encode(colour)}',
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colour,
                border: selected
                    ? Border.all(color: c.foreground, width: 2.5)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomReminderDialog extends StatefulWidget {
  const _CustomReminderDialog({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_CustomReminderDialog> createState() => _CustomReminderDialogState();
}

class _CustomReminderDialogState extends State<_CustomReminderDialog> {
  static const _units = {'minutes': 1, 'hours': 60, 'days': 1440};

  late String _unit;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final minutes = widget.initialMinutes;
    _unit = minutes % 1440 == 0 && minutes > 0
        ? 'days'
        : minutes % 60 == 0 && minutes > 0
            ? 'hours'
            : 'minutes';
    _controller =
        TextEditingController(text: '${minutes ~/ _units[_unit]!}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_controller.text.trim());
    if (amount == null || amount < 0) return;
    Navigator.pop(context, amount * _units[_unit]!);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom reminder'),
      content: Row(
        children: [
          SizedBox(
            width: 72,
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _unit,
            items: [
              for (final unit in _units.keys)
                DropdownMenuItem(value: unit, child: Text(unit)),
            ],
            onChanged: (value) => setState(() => _unit = value ?? _unit),
          ),
          const SizedBox(width: 8),
          const Flexible(child: Text('before')),
        ],
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

class _HuePickerDialog extends StatefulWidget {
  const _HuePickerDialog({required this.initial});

  final Color initial;

  @override
  State<_HuePickerDialog> createState() => _HuePickerDialogState();
}

class _HuePickerDialogState extends State<_HuePickerDialog> {
  late double _hue = HSVColor.fromColor(widget.initial).hue;
  double _shade = 0.85;

  Color get _colour => HSVColor.fromAHSV(1, _hue, 0.75, _shade).toColor();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom colour'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: _colour,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              gradient: LinearGradient(colors: [
                for (var h = 0; h <= 360; h += 60)
                  HSVColor.fromAHSV(1, h.toDouble(), 0.75, _shade).toColor(),
              ]),
            ),
          ),
          Slider(
            value: _hue,
            max: 360,
            label: 'Hue',
            onChanged: (value) => setState(() => _hue = value),
          ),
          Slider(
            value: _shade,
            min: 0.4,
            max: 1,
            label: 'Brightness',
            onChanged: (value) => setState(() => _shade = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _colour),
          child: const Text('Use colour'),
        ),
      ],
    );
  }
}
