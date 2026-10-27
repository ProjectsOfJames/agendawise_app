import 'package:flutter/material.dart';

import '../../../shared/widgets/screen_header.dart';

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(label: 'To-Do'),
            SizedBox(height: 16),
            ScreenTitle(eyebrow: 'Today', title: 'My Tasks'),
            Expanded(
              child: PlaceholderNote('Task list is built in later'),
            ),
          ],
        ),
      ),
    );
  }
}
