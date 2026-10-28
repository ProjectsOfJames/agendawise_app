import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/colour_hex.dart';
import '../../../core/utils/date_labels.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/time_text.dart';
import '../../tasks/presentation/priority_style.dart';
import '../application/calendar_providers.dart';
import '../domain/calendar_agenda.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];
const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _weekdayInitials = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

// Months are paged relative to January 2000.
final _baseMonth = DateTime(2000);
const _cellHeight = 52.0;
const _weekdayRowHeight = 24.0;
const _maxDots = 8;

int _pageFor(DateTime month) =>
    (month.year - _baseMonth.year) * 12 + month.month - _baseMonth.month;

DateTime _monthFor(int page) =>
    DateTime(_baseMonth.year, _baseMonth.month + page);

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late final PageController _pages =
      PageController(initialPage: _pageFor(ref.read(shownMonthProvider)));

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Selects today when it falls in [month], otherwise the 1st.
  void _showMonth(DateTime month) {
    final today = dateOnly(ref.read(clockProvider)());
    final inMonth = today.year == month.year && today.month == month.month;
    final current = ref.read(shownMonthProvider);
    if (current == month) return;
    ref.read(selectedDayProvider.notifier).select(inMonth ? today : month);
  }

  void _step(int delta) {
    if (!_pages.hasClients) return;
    _pages.animateToPage(
      (_pages.page?.round() ?? _pageFor(ref.read(shownMonthProvider))) + delta,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final selected = ref.watch(selectedDayProvider);
    final month = ref.watch(shownMonthProvider);
    final agendaAsync = ref.watch(monthAgendaProvider(month));
    final agenda = agendaAsync.asData?.value;
    final items = agenda?.itemsOn(selected) ?? const <AgendaItem>[];
    final today = dateOnly(ref.watch(clockProvider)());

    // Keeps the page in step when the selection moves to another month
    // from outside the pager.
    ref.listen(shownMonthProvider, (previous, next) {
      final page = _pageFor(next);
      if (_pages.hasClients && _pages.page?.round() != page) {
        _pages.jumpToPage(page);
      }
    });

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const ScreenHeader(label: 'Calendar'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ScreenTitle(
                  eyebrow: '${month.year}',
                  title: _months[month.month - 1],
                ),
              ),
              CircleIconButton(
                icon: Icons.chevron_left_rounded,
                semanticLabel: 'Previous month',
                onPressed: () => _step(-1),
              ),
              CircleIconButton(
                icon: Icons.chevron_right_rounded,
                semanticLabel: 'Next month',
                onPressed: () => _step(1),
              ),
              CircleIconButton(
                icon: Icons.add_rounded,
                semanticLabel: 'Add event',
                onPressed: () => context.push(AppRoutes.newEvent(selected)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _weekdayRowHeight + 6 * _cellHeight,
            child: PageView.builder(
              controller: _pages,
              onPageChanged: (page) => _showMonth(_monthFor(page)),
              itemBuilder: (context, page) => _MonthGrid(
                month: _monthFor(page),
                selected: selected,
                today: today,
                onSelect: (day) =>
                    ref.read(selectedDayProvider.notifier).select(day),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionLabel(
            '${_weekdays[selected.weekday - 1]}, '
            '${_months[selected.month - 1].substring(0, 3)} ${selected.day}',
          ),
          const SizedBox(height: 10),
          if (agendaAsync.hasError)
            Text('Could not load the calendar: ${agendaAsync.error}',
                style: TextStyle(color: c.destructive))
          else if (agenda == null)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: PlaceholderNote('Nothing planned for this day.'),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AgendaTile(item: item),
              ),
        ],
      ),
    );
  }
}

/// Colour of an item's dot on the month grid.
Color _dotColour(AgendaItem item, AppColors c) => switch (item.kind) {
      AgendaKind.event => ColourHex.decode(item.colourHex ?? '', fallback: c.primary),
      AgendaKind.task =>
        item.isDone ? c.success : priorityColour(item.priority!, c),
      AgendaKind.alarm => c.primary,
    };

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.today,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final agenda = ref.watch(monthAgendaProvider(month)).asData?.value;
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    // Weeks start on Sunday; DateTime.weekday is 1 (Mon) to 7 (Sun).
    final leading = DateTime(month.year, month.month).weekday % 7;
    final rows = (leading + dayCount + 6) ~/ 7;

    return Column(
      children: [
        SizedBox(
          height: _weekdayRowHeight,
          child: Row(
            children: [
              for (final initial in _weekdayInitials)
                Expanded(
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.mutedForeground,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (var row = 0; row < rows; row++)
          SizedBox(
            height: _cellHeight,
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _cell(
                      context,
                      row * 7 + col - leading + 1,
                      dayCount,
                      agenda,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(
    BuildContext context,
    int dayNumber,
    int dayCount,
    CalendarAgenda? agenda,
  ) {
    if (dayNumber < 1 || dayNumber > dayCount) return const SizedBox.shrink();
    final c = AppColors.of(context);
    final day = DateTime(month.year, month.month, dayNumber);
    final items = agenda?.itemsOn(day) ?? const <AgendaItem>[];
    final dots = [
      for (final item in items.take(_maxDots)) _dotColour(item, c),
    ];

    return _DayCell(
      day: day,
      selected: day == selected,
      today: day == today,
      dots: dots,
      itemCount: items.length,
      onTap: () => onSelect(day),
    );
  }
}

/// A day number with its items shown as coloured dots in a ring around it.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.today,
    required this.dots,
    required this.itemCount,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final List<Color> dots;
  final int itemCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final label = '${_weekdays[day.weekday - 1]} ${day.day}'
        '${itemCount == 0 ? '' : ', $itemCount ${itemCount == 1 ? 'item' : 'items'}'}'
        '${today ? ', today' : ''}';

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const dotSize = 5.0;
            final size = constraints.biggest.shortestSide;
            final ringRadius = size / 2 - dotSize / 2 - 1;
            final circle = (ringRadius - dotSize) * 2;
            return CustomPaint(
              painter: _DotRingPainter(
                dots: dots,
                radius: ringRadius,
                dotSize: dotSize,
              ),
              child: Center(
                child: Container(
                  width: circle,
                  height: circle,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? c.primary : null,
                    border: !selected && today
                        ? Border.all(color: c.primary, width: 1.5)
                        : null,
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected || today
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected
                            ? c.primaryForeground
                            : today
                                ? c.primary
                                : c.foreground,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DotRingPainter extends CustomPainter {
  _DotRingPainter({
    required this.dots,
    required this.radius,
    required this.dotSize,
  });

  final List<Color> dots;
  final double radius;
  final double dotSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (dots.isEmpty) return;
    final centre = size.center(Offset.zero);
    // A single dot sits under the number; more spread evenly from the top.
    final startAngle = dots.length == 1 ? math.pi / 2 : -math.pi / 2;
    final step = 2 * math.pi / dots.length;
    final paint = Paint();
    for (var i = 0; i < dots.length; i++) {
      final angle = startAngle + step * i;
      paint.color = dots[i];
      canvas.drawCircle(
        centre + Offset(math.cos(angle), math.sin(angle)) * radius,
        dotSize / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DotRingPainter old) =>
      old.radius != radius ||
      old.dotSize != dotSize ||
      !_sameColours(old.dots, dots);

  static bool _sameColours(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.item});

  final AgendaItem item;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final barColour = switch (item.kind) {
      AgendaKind.event => ColourHex.decode(item.colourHex ?? ''),
      AgendaKind.task =>
        item.isDone ? c.success : priorityColour(item.priority!, c),
      AgendaKind.alarm => c.primary,
    };
    final icon = switch (item.kind) {
      AgendaKind.event => null,
      AgendaKind.task =>
        item.isDone ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
      AgendaKind.alarm => Icons.notifications_none_rounded,
    };

    final time = item.time;
    final end = item.endTime;
    final when = item.allDay || time == null
        ? 'All day'
        : end == null
            ? formatTime(context, time)
            : '${formatTime(context, time)} – ${formatTime(context, end)}';
    final subtitle = [
      when,
      ?item.location,
      if (item.kind == AgendaKind.alarm) 'Alarm',
    ].join(' · ');

    final route = switch (item.kind) {
      AgendaKind.event => AppRoutes.event(item.id),
      AgendaKind.task => AppRoutes.task(item.id),
      AgendaKind.alarm => AppRoutes.alarm(item.id),
    };

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: BorderSide(color: c.border),
    );

    return Material(
      color: c.card,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                  color: barColour,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),
              if (icon != null) ...[
                Icon(icon, size: 20, color: c.mutedForeground),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.foreground,
                        decoration: item.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: c.mutedForeground),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
