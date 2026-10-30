import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../domain/backup_format.dart';

/// Reads and replaces the planner data as raw rows, so a restored database
/// is identical to the exported one, column for column.
class BackupRepository {
  BackupRepository(this._db);

  final AppDatabase _db;

  TableInfo<Table, Object?> _table(String name) =>
      _db.allTables.firstWhere((t) => t.actualTableName == name);

  /// Columns of every backed-up table in the current schema.
  Map<String, Set<String>> knownColumns() => {
        for (final name in backupTables)
          name: _table(name).$columns.map((c) => c.name).toSet(),
      };

  Future<Map<String, List<Map<String, Object?>>>> readAll() async {
    final result = <String, List<Map<String, Object?>>>{};
    for (final name in backupTables) {
      final rows = await _db.customSelect('SELECT * FROM "$name"',
          readsFrom: {_table(name)}).get();
      result[name] = [
        for (final row in rows)
          if (name != 'app_settings' ||
              !isDeviceOnlySetting('${row.data['key']}'))
            Map<String, Object?>.from(row.data),
      ];
    }
    return result;
  }

  /// The complete backup document as pretty-printed JSON.
  Future<String> exportJson(DateTime now) async {
    final tables = await readAll();
    return const JsonEncoder.withIndent('  ').convert({
      'app': backupAppName,
      'formatVersion': backupFormatVersion,
      'schemaVersion': _db.schemaVersion,
      'exportedAt': now.toUtc().toIso8601String(),
      'tables': tables,
    });
  }

  BackupContents parse(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const BackupException('This file is not an AgendaWise backup.');
    }
    return validateBackup(
      decoded,
      currentSchemaVersion: _db.schemaVersion,
      columns: knownColumns(),
    );
  }

  /// Replaces every planner row with the backup's rows in one transaction.
  /// If any row is rejected, nothing on the device changes.
  Future<void> restore(BackupContents backup) async {
    try {
      await _db.transaction(() async {
        for (final name in backupTables.reversed) {
          if (name == 'app_settings') {
            final keys = await _db
                .customSelect('SELECT key FROM app_settings')
                .map((r) => r.read<String>('key'))
                .get();
            final replaced = keys.where((k) => !isDeviceOnlySetting(k));
            await (_db.delete(_db.appSettings)
                  ..where((s) => s.key.isIn(replaced)))
                .go();
          } else {
            await _db.delete(_table(name)).go();
          }
        }
        for (final name in backupTables) {
          for (final row in backup.tables[name] ?? const []) {
            await _insert(name, row);
          }
        }
      });
    } on BackupException {
      rethrow;
    } on Object {
      throw const BackupException(
        'The backup could not be restored because some of its data is '
        'invalid. Nothing on this device was changed.',
      );
    }
  }

  Future<void> _insert(String name, Map<String, Object?> row) {
    final columns = row.keys.map((c) => '"$c"').join(', ');
    final marks = List.filled(row.length, '?').join(', ');
    return _db.customInsert(
      'INSERT INTO "$name" ($columns) VALUES ($marks)',
      variables: [for (final value in row.values) _variable(value)],
      updates: {_table(name)},
    );
  }

  static Variable<Object> _variable(Object? value) => switch (value) {
        final int v => Variable<int>(v),
        final String v => Variable<String>(v),
        _ => const Variable<Object>(null),
      };
}

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepository(ref.watch(appDatabaseProvider)),
);
