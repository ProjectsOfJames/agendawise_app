import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Pill-shaped choice chip; the selected pill is filled with [colour]
/// (the primary colour by default).
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.colour,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? colour;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final accent = colour ?? c.primary;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      side: BorderSide(
        color: selected ? accent : accent.withValues(alpha: 0.45),
        width: 1.2,
      ),
    );
    final textColour = selected ? c.primaryForeground : c.foreground;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? accent : c.card,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    Icon(leading, size: 16, color: textColour),
                    const SizedBox(width: 4),
                  ],
                  ExcludeSemantics(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: textColour,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
