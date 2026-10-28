import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Card row with a bold label on the left and a value or control on the
/// right, used on form screens.
class FormRowCard extends StatelessWidget {
  const FormRowCard({
    super.key,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: BorderSide(color: c.border),
    );
    return Material(
      color: c.card,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: EdgeInsets.only(left: 16, right: trailing == null ? 16 : 8),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.foreground,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? '',
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: c.mutedForeground),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
