import 'package:agendawise/app.dart';
import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/core/database/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const AgendaWiseApp(),
      ),
    );
    await _settle(tester);
  }

  // Removes the app so database streams are cancelled before the test ends.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('app starts on the Calendar tab', (tester) async {
    await pumpApp(tester);

    expect(find.text('CALENDAR'), findsOneWidget);
    expect(find.text('To-Do'), findsOneWidget);
    expect(find.text('Alarm'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('bottom nav switches tabs', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('To-Do'));
    await _settle(tester);
    expect(find.text('TO-DO'), findsOneWidget);
    expect(find.text('My Tasks'), findsOneWidget);
    expect(find.text('No tasks yet. Add one above.'), findsOneWidget);

    await tester.tap(find.text('Alarm'));
    await _settle(tester);
    expect(find.text('ALARMS'), findsOneWidget);

    await tester.tap(find.text('Calendar'));
    await _settle(tester);
    expect(find.text('CALENDAR'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('quick add puts a task in the list', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('To-Do'));
    await _settle(tester);

    await tester.enterText(find.byType(TextField), 'Call dentist');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _settle(tester);

    expect(find.text('Call dentist'), findsOneWidget);
    expect(find.text('1 remaining · 0 done'), findsOneWidget);

    await unmount(tester);
  });
}

/// Pumps a few frames without pumpAndSettle, which would never finish while
/// a loading spinner is animating.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
