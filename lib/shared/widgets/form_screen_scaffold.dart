import 'package:flutter/material.dart';

import 'circle_icon_button.dart';
import 'screen_header.dart';

/// Full-screen layout for forms: label and close control at the top,
/// scrolling content, and optional actions pinned to the bottom.
class FormScreenScaffold extends StatelessWidget {
  const FormScreenScaffold({
    super.key,
    required this.title,
    required this.onClose,
    this.bottom = const [],
    required this.children,
  });

  final String title;
  final VoidCallback onClose;
  final List<Widget> bottom;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: ScreenHeader(
                label: title,
                trailing: CircleIconButton(
                  icon: Icons.close_rounded,
                  semanticLabel: 'Close',
                  onPressed: onClose,
                ),
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
