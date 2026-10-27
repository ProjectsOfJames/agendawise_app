import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/interaction_logs_dao.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/domain/challenge_type.dart';
import '../../../core/domain/interaction_event_type.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/id_generator.dart';

/// Write side of the interaction history: one row per significant action.
class InteractionLogger {
  InteractionLogger(this._dao, this._ids, this._clock);

  final InteractionLogsDao _dao;
  final IdGenerator _ids;
  final Clock _clock;

  Future<void> alarmDismissed(String alarmId) => _write(
        InteractionEventType.alarmDismissed,
        alarmId: alarmId,
      );

  Future<void> alarmSnoozed(String alarmId) => _write(
        InteractionEventType.alarmSnoozed,
        alarmId: alarmId,
      );

  Future<void> challengeAttempt({
    required String? alarmId,
    required ChallengeType type,
    required int difficulty,
    required Duration duration,
    required bool success,
  }) =>
      _write(
        success
            ? InteractionEventType.challengeCompleted
            : InteractionEventType.challengeFailed,
        alarmId: alarmId,
        challengeType: type,
        difficulty: difficulty.clamp(1, 5),
        durationMs: duration.isNegative ? 0 : duration.inMilliseconds,
        success: success,
      );

  Future<void> taskCompleted(String taskId) => _write(
        InteractionEventType.taskCompleted,
        taskId: taskId,
      );

  Future<void> _write(
    InteractionEventType type, {
    String? alarmId,
    String? taskId,
    ChallengeType? challengeType,
    int? difficulty,
    int? durationMs,
    bool? success,
  }) =>
      _dao.insertLog(
        InteractionLogsCompanion.insert(
          id: _ids.next(),
          eventType: type,
          alarmId: Value(alarmId),
          taskId: Value(taskId),
          challengeType: Value(challengeType),
          difficulty: Value(difficulty),
          durationMs: Value(durationMs),
          success: Value(success),
          createdAt: _clock(),
        ),
      );
}

final interactionLoggerProvider = Provider<InteractionLogger>(
  (ref) => InteractionLogger(
    ref.watch(appDatabaseProvider).interactionLogsDao,
    ref.watch(idGeneratorProvider),
    ref.watch(clockProvider),
  ),
);
