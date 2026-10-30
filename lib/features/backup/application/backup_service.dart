import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cloud/activity_actions.dart';
import '../../../core/cloud/activity_logger.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/clock.dart';
import '../../account/domain/account_rules.dart';
import '../../alarms/application/schedule_sync.dart';
import '../../calendar/application/reminder_scheduler.dart';
import '../../calendar/data/event_repository.dart';
import '../data/backup_repository.dart';
import '../domain/backup_format.dart';

/// A backup file the user picked, already checked and ready to restore.
class PickedBackup {
  const PickedBackup({required this.fileName, required this.contents});

  final String fileName;
  final BackupContents contents;
}

/// Saves the planner data to a JSON file the user chooses, and restores it.
class BackupService {
  BackupService(this._ref);

  final Ref _ref;

  BackupRepository get _repo => _ref.read(backupRepositoryProvider);
  ActivityLogger get _activity => _ref.read(activityLoggerProvider);

  static String fileNameFor(DateTime now) =>
      'agendawise-backup-${dayStamp(now)}.json';

  /// Asks where to save the backup. Returns false if the user cancelled.
  Future<bool> export() async {
    final now = _ref.read(clockProvider)();
    final json = await _repo.exportJson(now);
    final Uri? saved;
    try {
      saved = await FilePicker.saveFile(
        dialogTitle: 'Save backup',
        fileName: fileNameFor(now),
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
    } on Object catch (error) {
      debugPrint('Backup not saved: $error');
      _activity.log(ActivityAction.backupExported, success: false);
      throw const BackupException('The backup could not be saved.');
    }
    if (saved == null) return false;
    _activity.log(ActivityAction.backupExported);
    return true;
  }

  /// Lets the user choose a backup file and validates it. Returns null if
  /// the user cancelled. Nothing is changed yet.
  Future<PickedBackup?> pick() async {
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return null;
    // The size can be unknown for some content providers.
    final size = await file.length();
    if (size != null && size > maxBackupBytes) {
      throw const BackupException('This file is too large to be a backup.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > maxBackupBytes) {
      throw const BackupException('This file is too large to be a backup.');
    }
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      throw const BackupException('This file is not an AgendaWise backup.');
    }
    return PickedBackup(fileName: file.name, contents: _repo.parse(text));
  }

  /// Replaces all planner data with [backup], then brings the theme,
  /// alarms and reminders in line with the restored data.
  Future<void> restore(BackupContents backup) async {
    final reminders = _ref.read(reminderSchedulerProvider);
    final oldEvents =
        await _ref.read(eventRepositoryProvider).getWithReminders();

    try {
      await _repo.restore(backup);
    } on BackupException {
      _activity.log(ActivityAction.backupImported, success: false);
      rethrow;
    }

    // Reminders of events that no longer exist would otherwise still fire.
    for (final event in oldEvents) {
      await reminders.cancel(event.id);
    }
    await _ref.read(themeModeProvider.notifier).restore();
    await _ref.read(scheduleSyncProvider).run();
    _activity.log(ActivityAction.backupImported);
  }
}

final backupServiceProvider = Provider<BackupService>(BackupService.new);
