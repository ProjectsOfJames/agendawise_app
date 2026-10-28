import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Explains why a permission or setting is needed before the system asks.
/// Returns true when the user chooses to continue.
Future<bool> showPermissionExplanation(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  String declineLabel = 'Not now',
  String acceptLabel = 'Continue',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final c = AppColors.of(dialogContext);
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      );
      return Dialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: c.primary, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: c.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(fontSize: 15, color: c.mutedForeground),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.foreground,
                          side: BorderSide(color: c.primary.withValues(alpha: 0.5)),
                          shape: shape,
                        ),
                        child: Text(declineLabel),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: FilledButton.styleFrom(shape: shape),
                        child: Text(acceptLabel),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
