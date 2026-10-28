import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/core/domain/challenge_type.dart';
import 'package:agendawise/core/domain/interaction_event_type.dart';
import 'package:agendawise/core/utils/id_generator.dart';
import 'package:agendawise/features/alarms/application/alarm_scheduler.dart';
import 'package:agendawise/features/alarms/application/ringing_controller.dart';
import 'package:agendawise/features/alarms/data/alarm_repository.dart';
import 'package:agendawise/features/challenges/application/challenge_controller.dart';
import 'package:agendawise/features/difficulty/data/interaction_log_repository.dart';
import 'package:agendawise/features/difficulty/data/interaction_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late AlarmRepository alarms;
  late InteractionLogger logger;
  late InteractionLogRepository logs;
  late ChallengeController controller;

  setUp(() {
    db = openTestDatabase();
    final clock = SteppingClock();
    const ids = IdGenerator();
    alarms = AlarmRepository(db, ids, clock.call);
    logger = InteractionLogger(db.interactionLogsDao, ids, clock.call);
    logs = InteractionLogRepository(db.interactionLogsDao);
    controller = ChallengeController(
      alarms: alarms,
      logger: logger,
      logs: logs,
      ringing: RingingController(
        alarms,
        const NoopAlarmScheduler(),
        const NoopAlarmScheduler(),
        logger,
      ),
    );
  });
  tearDown(() => db.close());

  Future<Alarm> createAlarm() async {
    final id = await alarms.create(const AlarmDraft(
      hour: 6,
      minute: 0,
      challengeType: ChallengeType.maths,
    ));
    return (await alarms.getById(id))!.alarm;
  }

  test('a failure is logged without changing the level', () async {
    final alarm = await createAlarm();
    await controller.recordFailure(
      alarm: alarm,
      type: ChallengeType.maths,
      level: 2,
      duration: const Duration(seconds: 12),
    );
    expect(await logs.count(InteractionEventType.challengeFailed), 1);
    expect((await alarms.getById(alarm.id))!.challenge!.difficulty, 2);
  });

  test('completing logs success, dismisses and keeps level with little history',
      () async {
    final alarm = await createAlarm();
    final next = await controller.complete(
      alarm: alarm,
      type: ChallengeType.maths,
      level: 2,
      duration: const Duration(seconds: 10),
    );
    expect(next, 2);
    expect(await logs.count(InteractionEventType.challengeCompleted), 1);
    expect(await logs.count(InteractionEventType.alarmDismissed), 1);
    // A one-off alarm is switched off once dismissed.
    expect((await alarms.getById(alarm.id))!.alarm.isActive, isFalse);
  });

  test('quick successes after slow history raise the stored level', () async {
    final alarm = await createAlarm();
    // Slow history.
    for (var i = 0; i < 10; i++) {
      await logger.challengeAttempt(
        alarmId: alarm.id,
        type: ChallengeType.maths,
        difficulty: 2,
        duration: const Duration(seconds: 60),
        success: true,
      );
    }
    // Recent quick solves.
    for (var i = 0; i < 9; i++) {
      await logger.challengeAttempt(
        alarmId: alarm.id,
        type: ChallengeType.maths,
        difficulty: 2,
        duration: const Duration(seconds: 5),
        success: true,
      );
    }
    final next = await controller.complete(
      alarm: alarm,
      type: ChallengeType.maths,
      level: 2,
      duration: const Duration(seconds: 5),
    );
    expect(next, 3);
    expect((await alarms.getById(alarm.id))!.challenge!.difficulty, 3);
  });

  test('repeated failures lower the stored level', () async {
    final alarm = await createAlarm();
    for (var i = 0; i < 5; i++) {
      await controller.recordFailure(
        alarm: alarm,
        type: ChallengeType.maths,
        level: 2,
        duration: const Duration(seconds: 20),
      );
    }
    final next = await controller.complete(
      alarm: alarm,
      type: ChallengeType.maths,
      level: 2,
      duration: const Duration(seconds: 20),
    );
    expect(next, 1);
  });
}
