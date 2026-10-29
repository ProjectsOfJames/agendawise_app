import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cloud/activity_actions.dart';
import '../../../core/cloud/activity_logger.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/alarms_dao.dart';
import '../../../core/domain/challenge_type.dart';
import '../../alarms/application/ringing_controller.dart';
import '../../alarms/data/alarm_repository.dart';
import '../../difficulty/data/interaction_log_repository.dart';
import '../../difficulty/data/interaction_logger.dart';
import '../../difficulty/domain/difficulty_adjuster.dart';

/// Records challenge attempts, adapts the alarm's difficulty and dismisses
/// the alarm once the challenge is solved.
class ChallengeController {
  ChallengeController({
    required AlarmRepository alarms,
    required InteractionLogger logger,
    required InteractionLogRepository logs,
    required RingingController ringing,
    DifficultyAdjuster adjuster = const DifficultyAdjuster(),
    ActivityLogger activity = const NoopActivityLogger(),
  })  : _activity = activity,
        _alarms = alarms,
        _logger = logger,
        _logs = logs,
        _ringing = ringing,
        _adjuster = adjuster;

  final AlarmRepository _alarms;
  final InteractionLogger _logger;
  final InteractionLogRepository _logs;
  final RingingController _ringing;
  final DifficultyAdjuster _adjuster;
  final ActivityLogger _activity;

  Future<AlarmWithChallenge?> load(String alarmId) => _alarms.getById(alarmId);

  Future<void> recordFailure({
    required Alarm alarm,
    required ChallengeType type,
    required int level,
    required Duration duration,
  }) =>
      _logger.challengeAttempt(
        alarmId: alarm.id,
        type: type,
        difficulty: level,
        duration: duration,
        success: false,
      );

  /// Logs the success, stores the next difficulty level for this alarm and
  /// dismisses it. Returns the new level.
  Future<int> complete({
    required Alarm alarm,
    required ChallengeType type,
    required int level,
    required Duration duration,
  }) async {
    await _logger.challengeAttempt(
      alarmId: alarm.id,
      type: type,
      difficulty: level,
      duration: duration,
      success: true,
    );
    final recent = await _logs.recentAttempts(type, limit: _adjuster.window);
    final average = await _logs.historicalAverageDuration(type) ?? duration;
    final next = _adjuster.adjust(
      current: level,
      recentNewestFirst: recent,
      historicalAverage: average,
    );
    final challenge = (await _alarms.getById(alarm.id))?.challenge;
    if (challenge != null && challenge.challengeType == type) {
      await _alarms.setChallengeDifficulty(alarm.id, next);
    }
    _activity.log(ActivityAction.challengeCompleted, meta: {
      'type': type.dbValue,
      'difficulty': level,
      'success': true,
      // Rounded to 5 seconds so timings cannot single anyone out.
      'seconds': (duration.inSeconds / 5).round() * 5,
    });
    await _ringing.dismiss(alarm);
    return next;
  }
}

final challengeControllerProvider = Provider<ChallengeController>(
  (ref) => ChallengeController(
    alarms: ref.watch(alarmRepositoryProvider),
    logger: ref.watch(interactionLoggerProvider),
    logs: ref.watch(interactionLogRepositoryProvider),
    ringing: ref.watch(ringingControllerProvider),
    activity: ref.watch(activityLoggerProvider),
  ),
);
