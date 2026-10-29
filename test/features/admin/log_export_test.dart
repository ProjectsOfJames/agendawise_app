import 'dart:convert';

import 'package:agendawise/core/cloud/activity_actions.dart';
import 'package:agendawise/features/admin/domain/admin_models.dart';
import 'package:agendawise/features/admin/domain/log_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final entries = [
    LogEntry(
      id: 'e1',
      uid: 'user-1',
      action: ActivityAction.challengeCompleted.wire,
      success: true,
      createdAt: DateTime.utc(2026, 10, 29, 8, 15),
      appVersion: '1.0.0',
      platform: 'android',
      meta: const {'type': 'math', 'seconds': 25},
    ),
    LogEntry(
      id: 'e2',
      uid: 'user-2',
      action: ActivityAction.signIn.wire,
      success: false,
      createdAt: DateTime.utc(2026, 10, 29, 9),
      appVersion: '1.0.0',
      platform: 'android',
      meta: const {},
    ),
  ];

  List<String> header({bool truncated = false}) => exportHeader(
        exportedBy: 'admin@example.com',
        exportedAt: DateTime.utc(2026, 10, 29, 10),
        filter: const LogFilter(),
        rows: entries.length,
        truncated: truncated,
      );

  test('header names the exporter, time, filters and row count', () {
    final lines = header();
    expect(lines, contains('Exported by: admin@example.com'));
    expect(lines, contains('Exported at: 2026-10-29T10:00:00.000Z'));
    expect(lines, contains('Date range: Last 7 days'));
    expect(lines, contains('Rows: 2'));
    expect(header(truncated: true).join('\n'), contains('limit reached'));
  });

  test('CSV has no email column unless emails are given', () {
    final csv = logsToCsv(entries: entries, header: header());
    final rows = const LineSplitter().convert(csv);
    final columns = rows.firstWhere((r) => r.startsWith('created_at'));
    expect(columns,
        'created_at,uid,action,outcome,app_version,platform,meta');
    expect(csv, isNot(contains('@example.org')));
  });

  test('CSV rows are escaped and include emails when asked', () {
    final csv = logsToCsv(
      entries: entries,
      header: header(),
      emails: {'user-1': 'one@example.org'},
    );
    final rows = const LineSplitter().convert(csv);
    final columns = rows.firstWhere((r) => r.startsWith('created_at'));
    expect(columns,
        'created_at,uid,email,action,outcome,app_version,platform,meta');
    final first = rows.firstWhere((r) => r.contains('user-1'));
    expect(
      first,
      '2026-10-29T08:15:00.000Z,user-1,one@example.org,challenge_completed,'
      'success,1.0.0,android,"{""type"":""math"",""seconds"":25}"',
    );
    final second = rows.firstWhere((r) => r.contains('user-2'));
    expect(second, contains(',user-2,,sign_in,failure,'));
  });

  test('header lines in CSV are marked as comments', () {
    final csv = logsToCsv(entries: entries, header: header());
    final rows = const LineSplitter().convert(csv);
    expect(rows.first, '# AgendaWise activity log export');
    // "Rows: 2" contains no comma, so it stays unquoted.
    expect(rows, contains('# Rows: 2'));
  });

  test('JSON export keeps the header and structured meta', () {
    final json = jsonDecode(logsToJson(entries: entries, header: header()))
        as Map<String, dynamic>;
    expect(json['header'], header());
    final list = json['entries'] as List;
    expect(list, hasLength(2));
    final first = list.first as Map<String, dynamic>;
    expect(first['meta'], {'type': 'math', 'seconds': 25});
    expect(first.containsKey('email'), isFalse);
    expect((list[1] as Map)['outcome'], 'failure');
  });
}
