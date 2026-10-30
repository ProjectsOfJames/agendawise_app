import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Full-width filled button used at the bottom of the voice screens.
class VoicePrimaryButton extends StatelessWidget {
  const VoicePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
        child: busy
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: c.primaryForeground,
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

/// Full-width outlined button used for secondary voice actions.
class VoiceOutlinedButton extends StatelessWidget {
  const VoiceOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c.foreground,
          backgroundColor: c.card,
          side: BorderSide(color: c.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Card with a small caption above a block of text, such as "Heard".
class HeardCard extends StatelessWidget {
  const HeardCard({super.key, required this.caption, required this.child});

  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caption, style: TextStyle(fontSize: 12, color: c.mutedForeground)),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

/// Card showing the title in bold with an "Edit" action on the right.
class VoiceTitleRow extends StatelessWidget {
  const VoiceTitleRow({
    super.key,
    required this.title,
    required this.onEdit,
    this.placeholder = false,
  });

  final String title;
  final VoidCallback onEdit;

  /// True when [title] is a prompt rather than a real title.
  final bool placeholder;

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
        onTap: onEdit,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: placeholder ? c.mutedForeground : c.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Edit',
                    style: TextStyle(fontSize: 13, color: c.mutedForeground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
