import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Bottom bar with a curved notch holding the raised mic button.
class AgendaBottomNav extends StatelessWidget {
  const AgendaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onMic,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onMic;

  static const double _barHeight = 76;
  static const double _overhang = 34;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: _barHeight + _overhang + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _barHeight + bottomInset,
            child: CustomPaint(
              painter: _NotchPainter(fill: c.navBg, line: c.navBorder),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        icon: Icons.calendar_month_outlined,
                        label: 'Calendar',
                        selected: currentIndex == 0,
                        onTap: () => onSelect(0),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _NavItem(
                            icon: Icons.check_box_outlined,
                            label: 'To-Do',
                            selected: currentIndex == 1,
                            onTap: () => onSelect(1),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.notifications_none_rounded,
                        label: 'Alarm',
                        selected: currentIndex == 2,
                        onTap: () => onSelect(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: _MicButton(onTap: onMic)),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = selected ? c.primary : c.mutedForeground;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 2),
              ExcludeSemantics(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      label: 'Voice input',
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.primary, Color.lerp(c.primary, c.foreground, 0.25)!],
          ),
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: 0.45),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Icon(
              Icons.mic_none_rounded,
              size: 26,
              color: c.primaryForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotchPainter extends CustomPainter {
  _NotchPainter({required this.fill, required this.line});

  final Color fill;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const half = 44.0, ease = 18.0, depth = 32.0;
    final top = Path()
      ..moveTo(0, 0)
      ..lineTo(cx - half - ease, 0)
      ..cubicTo(cx - half, 0, cx - half + 8, depth, cx, depth)
      ..cubicTo(cx + half - 8, depth, cx + half, 0, cx + half + ease, 0)
      ..lineTo(size.width, 0);
    final full = Path.from(top)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(full, Paint()..color = fill);
    canvas.drawPath(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = line,
    );
  }

  @override
  bool shouldRepaint(_NotchPainter old) => old.fill != fill || old.line != line;
}
