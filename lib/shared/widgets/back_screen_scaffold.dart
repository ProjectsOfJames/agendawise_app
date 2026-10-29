import 'package:flutter/material.dart';

import 'circle_icon_button.dart';
import 'screen_header.dart';

/// Full-screen layout with a back arrow and label at the top, scrolling
/// content and optional actions pinned to the bottom.
class BackScreenScaffold extends StatelessWidget {
  const BackScreenScaffold({
    super.key,
    required this.title,
    required this.onBack,
    this.bottom = const [],
    required this.children,
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> bottom;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 4),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.chevron_left_rounded,
                    semanticLabel: 'Back',
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: SectionLabel(title)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: children,
              ),
            ),
            if (bottom.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: bottom,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
