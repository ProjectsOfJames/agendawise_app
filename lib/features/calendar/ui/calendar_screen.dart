import 'package:flutter/material.dart';

import '../../../shared/widgets/screen_header.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(label: 'Calendar'),
            const SizedBox(height: 16),
            ScreenTitle(eyebrow: '${now.year}', title: _months[now.month - 1]),
            const Expanded(
              child: PlaceholderNote('Month grid is built in later'),
            ),
          ],
        ),
      ),
    );
  }
}
