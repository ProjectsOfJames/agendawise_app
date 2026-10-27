import 'package:drift/drift.dart';

import '../domain/challenge_type.dart';
import '../domain/interaction_event_type.dart';
import '../domain/task_priority.dart';

/// Stores [DateTime] values as milliseconds since the Unix epoch.
class EpochMsConverter extends TypeConverter<DateTime, int> {
  const EpochMsConverter();

  @override
  DateTime fromSql(int fromDb) => DateTime.fromMillisecondsSinceEpoch(fromDb);

  @override
  int toSql(DateTime value) => value.millisecondsSinceEpoch;
}

class TaskPriorityConverter extends TypeConverter<TaskPriority, String> {
  const TaskPriorityConverter();

  @override
  TaskPriority fromSql(String fromDb) => TaskPriority.fromDb(fromDb);

  @override
  String toSql(TaskPriority value) => value.dbValue;
}

class ChallengeTypeConverter extends TypeConverter<ChallengeType, String> {
  const ChallengeTypeConverter();

  @override
  ChallengeType fromSql(String fromDb) => ChallengeType.fromDb(fromDb);

  @override
  String toSql(ChallengeType value) => value.dbValue;
}

class InteractionEventTypeConverter
    extends TypeConverter<InteractionEventType, String> {
  const InteractionEventTypeConverter();

  @override
  InteractionEventType fromSql(String fromDb) =>
      InteractionEventType.fromDb(fromDb);

  @override
  String toSql(InteractionEventType value) => value.dbValue;
}
