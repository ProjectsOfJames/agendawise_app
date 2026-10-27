import 'package:drift/drift.dart';

import '../../domain/challenge_type.dart';
import '../../domain/interaction_event_type.dart';
import '../app_database.dart';
import '../tables.dart';

part 'interaction_logs_dao.g.dart';

final _challengeOutcomeValues = [
  InteractionEventType.challengeCompleted.dbValue,
  InteractionEventType.challengeFailed.dbValue,
];

@DriftAccessor(tables: [InteractionLogs])
class InteractionLogsDao extends DatabaseAccessor<AppDatabase>
    with _$InteractionLogsDaoMixin {
  InteractionLogsDao(super.attachedDatabase);

  Expression<bool> _isAttemptOf($InteractionLogsTable l, ChallengeType type) =>
      l.challengeType.equals(type.dbValue) &
      l.eventType.isIn(_challengeOutcomeValues);

  Future<void> insertLog(InteractionLogsCompanion log) =>
      into(interactionLogs).insert(log);

  /// Most recent challenge attempts of [type], newest first.
  Future<List<InteractionLog>> recentAttempts(
    ChallengeType type, {
    int limit = 10,
  }) =>
      (select(interactionLogs)
            ..where((l) => _isAttemptOf(l, type))
            ..orderBy([
              (l) => OrderingTerm.desc(l.createdAt),
              (l) => OrderingTerm.desc(l.rowId),
            ])
            ..limit(limit))
          .get();

  /// Average duration over every logged attempt of [type], or null if none.
  Future<double?> averageAttemptDurationMs(ChallengeType type) async {
    final average = interactionLogs.durationMs.avg();
    final query = selectOnly(interactionLogs)
      ..addColumns([average])
      ..where(_isAttemptOf(interactionLogs, type) &
          interactionLogs.durationMs.isNotNull());
    final row = await query.getSingle();
    return row.read(average);
  }

  Future<int> countByType(InteractionEventType type) async {
    final count = interactionLogs.id.count();
    final query = selectOnly(interactionLogs)
      ..addColumns([count])
      ..where(interactionLogs.eventType.equals(type.dbValue));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Stream<List<InteractionLog>> watchAll() => (select(interactionLogs)
        ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
      .watch();
}
