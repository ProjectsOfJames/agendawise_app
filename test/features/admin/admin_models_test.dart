import 'package:agendawise/core/cloud/activity_actions.dart';
import 'package:agendawise/features/admin/domain/admin_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 29, 15, 30);

  test('date presets start at local midnight of the right day', () {
    expect(DatePreset.today.start(now), DateTime(2026, 10, 29));
    expect(DatePreset.last7Days.start(now), DateTime(2026, 10, 23));
    expect(DatePreset.last30Days.start(now), DateTime(2026, 9, 30));
    expect(DatePreset.last12Months.start(now), DateTime(2025, 10, 29));
    expect(DatePreset.all.start(now), isNull);
  });

  test('only an admin can claim, and only after 180 days of inactivity', () {
    AdminStatus status(AdminRole role, DateTime? last) =>
        AdminStatus(role: role, superadminLastActive: last);

    final old = now.subtract(const Duration(days: 181));
    final recent = now.subtract(const Duration(days: 179));

    expect(status(AdminRole.admin, old).canClaim(now), isTrue);
    expect(status(AdminRole.admin, recent).canClaim(now), isFalse);
    expect(status(AdminRole.admin, null).canClaim(now), isFalse);
    expect(status(AdminRole.superadmin, old).canClaim(now), isFalse);
    expect(status(AdminRole.none, old).canClaim(now), isFalse);
  });

  test('filter limits keep "in" combinations within 30', () {
    expect(maxUserMatches * maxActionFilters, lessThanOrEqualTo(30));
  });

  test('copyWith can clear the user filter and keeps the rest', () {
    const filter = LogFilter(
      uids: {'u1'},
      userQuery: 'a@b.co',
      actions: {ActivityAction.signIn},
      datePreset: DatePreset.today,
      outcome: OutcomeFilter.failure,
    );
    final cleared = filter.copyWith(clearUser: true);
    expect(cleared.uids, isEmpty);
    expect(cleared.userQuery, isNull);
    expect(cleared.actions, {ActivityAction.signIn});
    expect(cleared.datePreset, DatePreset.today);
    expect(cleared.outcome, OutcomeFilter.failure);
  });

  test('describe lists every filter for the export header', () {
    const filter = LogFilter(
      userQuery: 'a@b.co',
      actions: {ActivityAction.signIn, ActivityAction.signOut},
    );
    expect(filter.describe(), [
      'Date range: Last 7 days',
      'User: a@b.co',
      'Actions: sign_in, sign_out',
      'Outcome: Any outcome',
    ]);
  });

  test('unknown stored actions are shown as they are', () {
    const entry = LogEntry(
      id: '1',
      uid: 'u',
      action: 'retired_action',
      success: true,
      createdAt: null,
      appVersion: '',
      platform: '',
      meta: {},
    );
    expect(entry.actionLabel, 'retired_action');
  });
}
