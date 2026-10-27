import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/alarms_dao.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/domain/challenge_type.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/id_generator.dart';

/// Starting difficulty for a newly attached challenge.
const initialChallengeDifficulty = 2;

/// Values entered on the alarm form.
class AlarmDraft {
  const AlarmDraft({
    required this.hour,
    required this.minute,
    this.title,
    this.repeatDays = 0,
    this.snoozeMinutes = 5,
    this.snoozeLimit,
    this.soundRef = 'tone_1',
    this.vibrate = true,
    this.isActive = true,
    this.challengeType,
  });

  final int hour;
  final int minute;
  final String? title;

  /// Bit 0 is Monday through bit 6 for Sunday.
  final int repeatDays;
  final int snoozeMinutes;

  /// Null means unlimited snoozes.
  final int? snoozeLimit;
  final String soundRef;
  final bool vibrate;
  final bool isActive;

  /// Null means no challenge.
  final ChallengeType? challengeType;
}

class AlarmRepository {
  AlarmRepository(this._db, this._ids, this._clock);

  final AppDatabase _db;
  final IdGenerator _ids;
  final Clock _clock;

  AlarmsDao get _dao => _db.alarmsDao;

  Stream<List<AlarmWithChallenge>> watchAll() => _dao.watchAllWithChallenges();

  Future<AlarmWithChallenge?> getById(String id) => _dao.getWithChallenge(id);

  Future<List<Alarm>> getActive() => _dao.getActive();

  Future<String> create(AlarmDraft draft) async {
    final id = _ids.next();
    final now = _clock();
    final type = draft.challengeType;
    await _dao.insertAlarm(
      AlarmsCompanion.insert(
        id: id,
        title: Value(_cleanTitle(draft.title)),
        hour: draft.hour,
        minute: draft.minute,
        repeatDays: Value(draft.repeatDays),
        snoozeMinutes: Value(draft.snoozeMinutes),
        snoozeLimit: Value(draft.snoozeLimit),
        soundRef: Value(draft.soundRef),
        vibrate: Value(draft.vibrate),
        isActive: Value(draft.isActive),
        createdAt: now,
        updatedAt: now,
      ),
      challenge: type == null ? null : _newChallenge(id, type),
    );
    return id;
  }

  /// Keeps the learned difficulty when the challenge type is unchanged.
  Future<void> update(String id, AlarmDraft draft) => _db.transaction(() async {
        await _dao.updateAlarm(
          id,
          AlarmsCompanion(
            title: Value(_cleanTitle(draft.title)),
            hour: Value(draft.hour),
            minute: Value(draft.minute),
            repeatDays: Value(draft.repeatDays),
            snoozeMinutes: Value(draft.snoozeMinutes),
            snoozeLimit: Value(draft.snoozeLimit),
            soundRef: Value(draft.soundRef),
            vibrate: Value(draft.vibrate),
            isActive: Value(draft.isActive),
            updatedAt: Value(_clock()),
          ),
        );
        final current = await _dao.getChallenge(id);
        final type = draft.challengeType;
        if (type == null) {
          if (current != null) await _dao.deleteChallenge(id);
        } else if (current == null) {
          await _dao.insertChallenge(_newChallenge(id, type));
        } else if (current.challengeType != type) {
          await _dao.updateChallenge(
            id,
            AlarmChallengesCompanion(
              challengeType: Value(type),
              difficulty: const Value(initialChallengeDifficulty),
            ),
          );
        }
      });

  Future<void> setActive(String id, bool active) => _dao.updateAlarm(
        id,
        AlarmsCompanion(isActive: Value(active), updatedAt: Value(_clock())),
      );

  Future<void> setChallengeDifficulty(String alarmId, int level) =>
      _dao.updateChallenge(
        alarmId,
        AlarmChallengesCompanion(difficulty: Value(level.clamp(1, 5))),
      );

  /// The challenge is removed by ON DELETE CASCADE; logs keep their history.
  Future<void> delete(String id) => _dao.deleteAlarm(id);

  AlarmChallengesCompanion _newChallenge(String alarmId, ChallengeType type) =>
      AlarmChallengesCompanion.insert(
        id: _ids.next(),
        alarmId: alarmId,
        challengeType: type,
        difficulty: const Value(initialChallengeDifficulty),
      );

  String? _cleanTitle(String? title) {
    final clean = title?.trim();
    return (clean == null || clean.isEmpty) ? null : clean;
  }
}

final alarmRepositoryProvider = Provider<AlarmRepository>(
  (ref) => AlarmRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(idGeneratorProvider),
    ref.watch(clockProvider),
  ),
);
