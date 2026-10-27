import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/interaction_logs_dao.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/domain/challenge_type.dart';
import '../../../core/domain/interaction_event_type.dart';
import '../domain/challenge_attempt.dart';

/// Read side of the interaction history.
class InteractionLogRepository {
  InteractionLogRepository(this._dao);

  final InteractionLogsDao _dao;

  /// Newest first; at most [limit] attempts.
  Future<List<ChallengeAttempt>> recentAttempts(
    ChallengeType type, {
    int limit = 10,
  }) async {
    final rows = await _dao.recentAttempts(type, limit: limit);
    return rows.map(_toAttempt).toList();
  }

  Future<Duration?> historicalAverageDuration(ChallengeType type) async {
    final averageMs = await _dao.averageAttemptDurationMs(type);
    return averageMs == null
        ? null
        : Duration(milliseconds: averageMs.round());
  }

  Future<int> count(InteractionEventType type) => _dao.countByType(type);

  Stream<List<InteractionLog>> watchAll() => _dao.watchAll();

  ChallengeAttempt _toAttempt(InteractionLog row) => ChallengeAttempt(
        type: row.challengeType!,
        difficulty: row.difficulty ?? 1,
        duration: Duration(milliseconds: row.durationMs ?? 0),
        success: row.eventType == InteractionEventType.challengeCompleted,
        at: row.createdAt,
      );
}

final interactionLogRepositoryProvider = Provider<InteractionLogRepository>(
  (ref) => InteractionLogRepository(
    ref.watch(appDatabaseProvider).interactionLogsDao,
  ),
);
