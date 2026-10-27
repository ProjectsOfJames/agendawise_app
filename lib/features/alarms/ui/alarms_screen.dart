import 'package:flutter/material.dart';

import '../../../shared/widgets/screen_header.dart';

class AlarmsScreen extends StatelessWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(label: 'Alarms'),
            SizedBox(height: 16),
            ScreenTitle(eyebrow: 'Active', title: 'Alarms'),
            Expanded(
              child: PlaceholderNote('Alarm list is built in later'),
            ),
          ],
        ),
      ),
    );
  }
}
