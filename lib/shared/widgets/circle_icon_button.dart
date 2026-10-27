import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 36 px circular icon button with a 44 px touch target.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkResponse(
        onTap: onPressed,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.secondary,
                border: Border.all(color: c.primary.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, size: 20, color: c.primary),
            ),
          ),
        ),
      ),
    );
  }
}
