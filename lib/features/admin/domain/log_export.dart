import 'dart:convert';

import 'admin_models.dart';

String _iso(DateTime? value) => value?.toUtc().toIso8601String() ?? '';

String _csvCell(Object? value) {
  final text = value?.toString() ?? '';
  final needsQuotes = text.contains(RegExp(r'[",\r\n]'));
  final escaped = text.replaceAll('"', '""');
  return needsQuotes ? '"$escaped"' : escaped;
}

String _csvRow(List<Object?> cells) => cells.map(_csvCell).join(',');

/// Lines describing who exported what and when, placed above the data.
List<String> exportHeader({
  required String exportedBy,
  required DateTime exportedAt,
  required LogFilter filter,
  required int rows,
  required bool truncated,
}) =>
    [
      'AgendaWise activity log export',
      'Exported by: $exportedBy',
      'Exported at: ${_iso(exportedAt)}',
      ...filter.describe(),
      'Rows: $rows${truncated ? ' (limit reached; narrow the filters for the rest)' : ''}',
      'Delete this file once it is no longer needed.',
    ];

/// CSV with header lines prefixed by "#", then one row per entry. The email
/// column is included only when [emails] is given.
String logsToCsv({
  required List<LogEntry> entries,
  required List<String> header,
  Map<String, String>? emails,
}) {
  final buffer = StringBuffer();
  for (final line in header) {
    buffer.writeln(_csvCell('# $line'));
  }
  buffer.writeln(_csvRow([
    'created_at',
    'uid',
    if (emails != null) 'email',
    'action',
    'outcome',
    'app_version',
    'platform',
    'meta',
  ]));
  for (final e in entries) {
    buffer.writeln(_csvRow([
      _iso(e.createdAt),
      e.uid,
      if (emails != null) emails[e.uid] ?? '',
      e.action,
      e.success ? 'success' : 'failure',
      e.appVersion,
      e.platform,
      e.meta.isEmpty ? '' : jsonEncode(e.meta),
    ]));
  }
  return buffer.toString();
}

String logsToJson({
  required List<LogEntry> entries,
  required List<String> header,
  Map<String, String>? emails,
}) {
  final data = {
    'header': header,
    'entries': [
      for (final e in entries)
        {
          'createdAt': _iso(e.createdAt),
          'uid': e.uid,
          if (emails != null) 'email': emails[e.uid],
          'action': e.action,
          'outcome': e.success ? 'success' : 'failure',
          'appVersion': e.appVersion,
          'platform': e.platform,
          'meta': e.meta,
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(data);
}
