/// Name written into every backup so other JSON files are rejected.
const backupAppName = 'AgendaWise';

/// Version of the backup layout itself (not the database schema).
const backupFormatVersion = 1;

/// Larger files are refused before parsing.
const maxBackupBytes = 20 * 1024 * 1024;

/// Tables in the order they are restored, parents before children, so
/// every foreign key points at a row that already exists. The account table
/// is never part of a backup.
const backupTables = [
  'categories',
  'alarms',
  'alarm_challenges',
  'calendar_events',
  'tasks',
  'notes',
  'interaction_logs',
  'app_settings',
];

/// Settings that describe this device or the signed-in account rather than
/// the user's planner data. They are neither exported nor replaced.
const deviceOnlySettingKeys = {
  'signed_in_user_id',
  'alarm_volume_before_challenge',
  'battery_prompt_shown',
  'overlay_prompt_shown',
};

bool isDeviceOnlySetting(String key) =>
    key.startsWith('account_') || deviceOnlySettingKeys.contains(key);

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A backup that passed validation and is ready to restore.
class BackupContents {
  const BackupContents({
    required this.schemaVersion,
    required this.exportedAt,
    required this.tables,
  });

  final int schemaVersion;
  final DateTime? exportedAt;

  /// Rows per table, each row a column-to-value map.
  final Map<String, List<Map<String, Object?>>> tables;

  int count(String table) => tables[table]?.length ?? 0;

  int get totalRows =>
      tables.values.fold(0, (sum, rows) => sum + rows.length);
}

/// Checks the decoded JSON of a backup against the known tables and
/// columns. [columns] maps each table to the columns this app version has.
BackupContents validateBackup(
  Object? decoded, {
  required int currentSchemaVersion,
  required Map<String, Set<String>> columns,
}) {
  const notBackup = BackupException('This file is not an AgendaWise backup.');
  if (decoded is! Map<String, dynamic>) throw notBackup;
  if (decoded['app'] != backupAppName) throw notBackup;

  final format = decoded['formatVersion'];
  final schema = decoded['schemaVersion'];
  if (format is! int || schema is! int) throw notBackup;
  if (format > backupFormatVersion || schema > currentSchemaVersion) {
    throw const BackupException(
      'This backup was made by a newer version of AgendaWise. Update the app '
      'and try again.',
    );
  }

  final rawTables = decoded['tables'];
  if (rawTables is! Map<String, dynamic>) throw notBackup;

  final tables = <String, List<Map<String, Object?>>>{};
  for (final entry in rawTables.entries) {
    final known = columns[entry.key];
    if (known == null || !backupTables.contains(entry.key)) {
      throw BackupException('The backup contains an unknown table '
          '"${entry.key}".');
    }
    final rawRows = entry.value;
    if (rawRows is! List) throw notBackup;
    final rows = <Map<String, Object?>>[];
    for (final rawRow in rawRows) {
      if (rawRow is! Map<String, dynamic>) throw notBackup;
      final row = <String, Object?>{};
      for (final cell in rawRow.entries) {
        if (!known.contains(cell.key)) {
          throw BackupException('The backup contains an unknown column '
              '"${entry.key}.${cell.key}".');
        }
        row[cell.key] = _cellValue(cell.value);
      }
      if (row.isEmpty) throw notBackup;
      if (entry.key == 'app_settings' &&
          isDeviceOnlySetting('${row['key']}')) {
        continue;
      }
      rows.add(row);
    }
    tables[entry.key] = rows;
  }

  final exportedAt = decoded['exportedAt'];
  return BackupContents(
    schemaVersion: schema,
    exportedAt: exportedAt is String ? DateTime.tryParse(exportedAt) : null,
    tables: tables,
  );
}

/// SQLite values in this database are integers, text or null.
Object? _cellValue(Object? value) {
  if (value == null || value is int || value is String) return value;
  if (value is double && value == value.roundToDouble()) return value.toInt();
  if (value is bool) return value ? 1 : 0;
  throw const BackupException('The backup contains a value of an unexpected '
      'type.');
}
