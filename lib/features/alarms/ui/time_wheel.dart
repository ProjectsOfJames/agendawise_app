import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

const _itemExtent = 56.0;
const _visibleRows = 3;

/// Scroll wheels for hour and minute, with an AM/PM wheel when the device
/// uses the 12-hour clock. Reports the time as 24-hour values.
class TimeWheel extends StatefulWidget {
  const TimeWheel({
    super.key,
    required this.hour,
    required this.minute,
    required this.use24Hour,
    required this.onChanged,
  });

  final int hour;
  final int minute;
  final bool use24Hour;
  final void Function(int hour, int minute) onChanged;

  @override
  State<TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<TimeWheel> {
  late int _hour = widget.hour;
  late int _minute = widget.minute;

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late final FixedExtentScrollController _periodController;

  bool get _isPm => _hour >= 12;

  /// Index on the hour wheel: 0-23, or 0-11 for 12 to 11 o'clock.
  int get _hourIndex => widget.use24Hour ? _hour : _hour % 12;

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(initialItem: _hourIndex);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
    _periodController = FixedExtentScrollController(initialItem: _isPm ? 1 : 0);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_hour, _minute);

  void _onHour(int index) {
    final hours = widget.use24Hour ? 24 : 12;
    final value = index % hours;
    setState(() {
      _hour = widget.use24Hour ? value : value + (_isPm ? 12 : 0);
    });
    _emit();
  }

  void _onMinute(int index) {
    setState(() => _minute = index % 60);
    _emit();
  }

  void _onPeriod(int index) {
    setState(() => _hour = _hour % 12 + (index == 1 ? 12 : 0));
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hourLabels = widget.use24Hour
        ? [for (var h = 0; h < 24; h++) h.toString().padLeft(2, '0')]
        : ['12', for (var h = 1; h < 12; h++) '$h'];

    return Container(
      height: _itemExtent * _visibleRows + 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _Wheel(
              label: 'Hour',
              controller: _hourController,
              labels: hourLabels,
              selected: _hourIndex,
              looping: true,
              onSelected: _onHour,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: c.foreground,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: _Wheel(
              label: 'Minute',
              controller: _minuteController,
              labels: [for (var m = 0; m < 60; m++) m.toString().padLeft(2, '0')],
              selected: _minute,
              looping: true,
              onSelected: _onMinute,
            ),
          ),
          if (!widget.use24Hour) ...[
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _Wheel(
                label: 'AM or PM',
                controller: _periodController,
                labels: const ['AM', 'PM'],
                selected: _isPm ? 1 : 0,
                looping: false,
                fontSize: 24,
                onSelected: _onPeriod,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.label,
    required this.controller,
    required this.labels,
    required this.selected,
    required this.looping,
    required this.onSelected,
    this.fontSize = 36,
  });

  final String label;
  final FixedExtentScrollController controller;
  final List<String> labels;
  final int selected;
  final bool looping;
  final ValueChanged<int> onSelected;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final children = [
      for (var i = 0; i < labels.length; i++)
        Center(
          child: Text(
            labels[i],
            style: TextStyle(
              fontSize: i == selected ? fontSize : fontSize * 0.8,
              fontWeight: i == selected ? FontWeight.w600 : FontWeight.w400,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: i == selected
                  ? c.foreground
                  : c.mutedForeground.withValues(alpha: 0.7),
            ),
          ),
        ),
    ];

    return Semantics(
      label: label,
      value: labels[selected],
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: _itemExtent - 4,
            decoration: BoxDecoration(
              color: c.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: _itemExtent,
            diameterRatio: 1.8,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onSelected,
            childDelegate: looping
                ? ListWheelChildLoopingListDelegate(children: children)
                : ListWheelChildListDelegate(children: children),
          ),
        ],
      ),
    );
  }
}
