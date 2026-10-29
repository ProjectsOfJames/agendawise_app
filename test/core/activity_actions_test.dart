import 'package:agendawise/core/cloud/activity_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every action survives a round trip through its stored name', () {
    for (final action in ActivityAction.values) {
      expect(ActivityAction.fromWire(action.wire), action);
    }
    expect(ActivityAction.fromWire('not_an_action'), isNull);
    expect(ActivityAction.fromWire(null), isNull);
  });

  test('stored names are unique, short and snake_case', () {
    final names = ActivityAction.values.map((a) => a.wire).toList();
    expect(names.toSet().length, names.length);
    for (final name in names) {
      expect(name, matches(RegExp(r'^[a-z]+(_[a-z]+)*$')));
      expect(name.length, lessThanOrEqualTo(40));
    }
  });

  test('only usage actions depend on the usage opt-in', () {
    for (final action in ActivityAction.values) {
      expect(action.needsOptIn, action.group == ActivityGroup.usage,
          reason: action.wire);
    }
    expect(ActivityAction.signIn.needsOptIn, isFalse);
    expect(ActivityAction.adminLogsExported.needsOptIn, isFalse);
    expect(ActivityAction.taskCreated.needsOptIn, isTrue);
  });

  test('every group has at least one action', () {
    for (final group in ActivityGroup.values) {
      expect(ActivityAction.values.any((a) => a.group == group), isTrue,
          reason: group.label);
    }
  });
}
