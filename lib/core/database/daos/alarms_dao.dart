import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'alarms_dao.g.dart';

class AlarmWithChallenge {
  const AlarmWithChallenge({required this.alarm, this.challenge});

  final Alarm alarm;
  final AlarmChallenge? challenge;
}

@DriftAccessor(tables: [Alarms, AlarmChallenges])
class AlarmsDao extends DatabaseAccessor<AppDatabase> with _$AlarmsDaoMixin {
  AlarmsDao(super.attachedDatabase);

  JoinedSelectStatement<HasResultSet, dynamic> _joined() =>
      select(alarms).join([
        leftOuterJoin(
          alarmChallenges,
          alarmChallenges.alarmId.equalsExp(alarms.id),
        ),
      ]);

  AlarmWithChallenge _read(TypedResult row) => AlarmWithChallenge(
        alarm: row.readTable(alarms),
        challenge: row.readTableOrNull(alarmChallenges),
      );

  Stream<List<AlarmWithChallenge>> watchAllWithChallenges() {
    final query = _joined()
      ..orderBy([OrderingTerm.asc(alarms.hour), OrderingTerm.asc(alarms.minute)]);
    return query.watch().map((rows) => rows.map(_read).toList());
  }

  Future<AlarmWithChallenge?> getWithChallenge(String id) async {
    final query = _joined()..where(alarms.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _read(row);
  }

  Future<List<Alarm>> getActive() =>
      (select(alarms)..where((a) => a.isActive.equals(true))).get();

  Future<void> insertAlarm(
    AlarmsCompanion alarm, {
    AlarmChallengesCompanion? challenge,
  }) =>
      transaction(() async {
        await into(alarms).insert(alarm);
        if (challenge != null) {
          await into(alarmChallenges).insert(challenge);
        }
      });

  Future<int> updateAlarm(String id, AlarmsCompanion changes) =>
      (update(alarms)..where((a) => a.id.equals(id))).write(changes);

  Future<int> deleteAlarm(String id) =>
      (delete(alarms)..where((a) => a.id.equals(id))).go();

  Future<AlarmChallenge?> getChallenge(String alarmId) =>
      (select(alarmChallenges)..where((c) => c.alarmId.equals(alarmId)))
          .getSingleOrNull();

  Future<void> insertChallenge(AlarmChallengesCompanion challenge) =>
      into(alarmChallenges).insert(challenge);

  Future<int> updateChallenge(
    String alarmId,
    AlarmChallengesCompanion changes,
  ) =>
      (update(alarmChallenges)..where((c) => c.alarmId.equals(alarmId)))
          .write(changes);

  Future<int> deleteChallenge(String alarmId) =>
      (delete(alarmChallenges)..where((c) => c.alarmId.equals(alarmId))).go();
}
