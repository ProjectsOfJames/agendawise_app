import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'circle_icon_button.dart';

/// Small uppercase section label used across screens.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: AppColors.of(context).mutedForeground,
      ),
    );
  }
}

/// Top bar: screen label on the left, profile button on the right.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SectionLabel(label),
        const Spacer(),
        trailing ??
            CircleIconButton(
              icon: Icons.account_circle_outlined,
              semanticLabel: 'Profile',
              onPressed: () => context.push('/profile'),
            ),
      ],
    );
  }
}

/// Eyebrow label, large title and optional subtitle.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            color: c.mutedForeground,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: c.foreground,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 13, color: c.mutedForeground),
          ),
        ],
      ],
    );
  }
}

/// Temporary note shown on tabs until they are built.
class PlaceholderNote extends StatelessWidget {
  const PlaceholderNote(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.of(context).mutedForeground),
      ),
    );
  }
}
