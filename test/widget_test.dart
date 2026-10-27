import 'package:agendawise/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bottom nav switches tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgendaWiseApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('To-Do'));
    await tester.pumpAndSettle();
    expect(find.text('My Tasks'), findsOneWidget);

    await tester.tap(find.text('Alarm'));
    await tester.pumpAndSettle();
    expect(find.text('ACTIVE'), findsOneWidget);
  });

  testWidgets('profile opens and closes', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgendaWiseApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Light mode'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Light mode'), findsNothing);
  });
}
