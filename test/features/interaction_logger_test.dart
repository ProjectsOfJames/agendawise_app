import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/core/domain/challenge_type.dart';
import 'package:agendawise/core/domain/interaction_event_type.dart';
import 'package:agendawise/core/utils/id_generator.dart';
import 'package:agendawise/features/difficulty/data/interaction_log_repository.dart';
import 'package:agendawise/features/difficulty/data/interaction_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late InteractionLogger logger;
  late InteractionLogRepository logs;

  setUp(() {
    db = openTestDatabase();
    logger = InteractionLogger(
      db.interactionLogsDao,
      const IdGenerator(),
      SteppingClock().call,
    );
    logs = InteractionLogRepository(db.interactionLogsDao);
  });
  tearDown(() => db.close());

  Future<void> attempt(
    int seconds, {
    bool success = true,
    ChallengeType type = ChallengeType.maths,
  }) =>
      logger.challengeAttempt(
        alarmId: null,
        type: type,
        difficulty: 2,
        duration: Duration(seconds: seconds),
        success: success,
      );

  test('alarm, challenge and task events are counted separately', () async {
    await db.customStatement(
      "INSERT INTO alarms (id, hour, minute, created_at, updated_at) "
      "VALUES ('a', 7, 0, 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO tasks (id, title, created_at) VALUES ('t', 'Report', 0)",
    );

    await logger.alarmSnoozed('a');
    await logger.alarmSnoozed('a');
    await logger.alarmDismissed('a');
    await attempt(8);
    await attempt(20, success: false);
    await logger.taskCompleted('t');

    expect(await logs.count(InteractionEventType.alarmSnoozed), 2);
    expect(await logs.count(InteractionEventType.alarmDismissed), 1);
    expect(await logs.count(InteractionEventType.challengeCompleted), 1);
    expect(await logs.count(InteractionEventType.challengeFailed), 1);
    expect(await logs.count(InteractionEventType.taskCompleted), 1);
  });

  test('recent attempts are the newest ten of that type only', () async {
    for (var i = 1; i <= 12; i++) {
      await attempt(i);
    }
    await attempt(99, type: ChallengeType.shake);

    final recent = await logs.recentAttempts(ChallengeType.maths);
    expect(recent, hasLength(10));
    expect(recent.first.duration, const Duration(seconds: 12));
    expect(recent.last.duration, const Duration(seconds: 3));
    expect(recent.every((a) => a.type == ChallengeType.maths), isTrue);
  });

  test('success flag follows the logged outcome', () async {
    await attempt(5);
    await attempt(6, success: false);
    final recent = await logs.recentAttempts(ChallengeType.maths);
    expect(recent.map((a) => a.success), [false, true]);
  });

  test('historical average covers all attempts of the type', () async {
    expect(await logs.historicalAverageDuration(ChallengeType.memory), isNull);
    for (final seconds in [10, 20, 30]) {
      await attempt(seconds, type: ChallengeType.memory);
    }
    await attempt(100, type: ChallengeType.phrase);
    expect(
      await logs.historicalAverageDuration(ChallengeType.memory),
      const Duration(seconds: 20),
    );
  });

  test('difficulty is clamped and negative durations become zero', () async {
    await logger.challengeAttempt(
      alarmId: null,
      type: ChallengeType.phrase,
      difficulty: 8,
      duration: const Duration(seconds: -3),
      success: true,
    );
    final only = (await logs.recentAttempts(ChallengeType.phrase)).single;
    expect(only.difficulty, 5);
    expect(only.duration, Duration.zero);
  });
}
