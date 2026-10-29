import 'package:drift/drift.dart';

import 'converters.dart';

// Column constraints are written as SQL so the schema matches the documented
// design exactly. clientDefault keeps defaulted columns optional in companions.

@DataClassName('User')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()
      .customConstraint('NOT NULL CHECK (length(trim(full_name)) > 0)')();
  TextColumn get email =>
      text().customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();
  TextColumn get passwordHash => text()();
  TextColumn get salt => text()();
  TextColumn get imagePath => text().nullable()();
  IntColumn get createdAt => integer().map(const EpochMsConverter())();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AppSetting')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('TaskCategory')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().customConstraint(
      'NOT NULL UNIQUE COLLATE NOCASE CHECK (length(trim(name)) > 0)')();
  TextColumn get colour => text().customConstraint(
      "NOT NULL CHECK (length(colour) = 7 AND substr(colour, 1, 1) = '#')")();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Alarm')
class Alarms extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().nullable()();
  IntColumn get hour =>
      integer().customConstraint('NOT NULL CHECK (hour BETWEEN 0 AND 23)')();
  IntColumn get minute =>
      integer().customConstraint('NOT NULL CHECK (minute BETWEEN 0 AND 59)')();
  IntColumn get repeatDays => integer()
      .customConstraint(
          'NOT NULL DEFAULT 0 CHECK (repeat_days BETWEEN 0 AND 127)')
      .clientDefault(() => 0)();
  IntColumn get snoozeMinutes => integer()
      .customConstraint(
          'NOT NULL DEFAULT 5 CHECK (snooze_minutes BETWEEN 1 AND 120)')
      .clientDefault(() => 5)();
  IntColumn get snoozeLimit => integer().nullable().customConstraint(
      'CHECK (snooze_limit IS NULL OR snooze_limit BETWEEN 1 AND 20)')();
  TextColumn get soundRef => text()
      .customConstraint("NOT NULL DEFAULT 'tone_1'")
      .clientDefault(() => 'tone_1')();
  BoolColumn get vibrate => boolean()
      .customConstraint('NOT NULL DEFAULT 1 CHECK (vibrate IN (0, 1))')
      .clientDefault(() => true)();
  BoolColumn get isActive => boolean()
      .customConstraint('NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))')
      .clientDefault(() => true)();

  /// Date of a one-off alarm tied to a specific day (for example a task's
  /// linked alarm). Null for alarms that ring at the next matching time.
  IntColumn get ringOn => integer().nullable().map(const EpochMsConverter())();
  IntColumn get createdAt => integer().map(const EpochMsConverter())();
  IntColumn get updatedAt => integer().map(const EpochMsConverter())();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AlarmChallenge')
class AlarmChallenges extends Table {
  TextColumn get id => text()();
  TextColumn get alarmId => text().customConstraint(
      'NOT NULL UNIQUE REFERENCES alarms (id) ON DELETE CASCADE')();
  TextColumn get challengeType => text()
      .customConstraint(
          "NOT NULL CHECK (challenge_type IN ('maths', 'memory', 'phrase', 'shake'))")
      .map(const ChallengeTypeConverter())();
  IntColumn get difficulty => integer()
      .customConstraint('NOT NULL DEFAULT 2 CHECK (difficulty BETWEEN 1 AND 5)')
      .clientDefault(() => 2)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CalendarEvent')
class CalendarEvents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()
      .customConstraint(
          "NOT NULL DEFAULT 'My event' CHECK (length(trim(title)) > 0)")
      .clientDefault(() => 'My event')();
  IntColumn get startAt => integer().map(const EpochMsConverter())();
  IntColumn get endAt => integer().map(const EpochMsConverter())();
  BoolColumn get isAllDay => boolean()
      .customConstraint('NOT NULL DEFAULT 0 CHECK (is_all_day IN (0, 1))')
      .clientDefault(() => false)();
  TextColumn get location => text().nullable()();
  TextColumn get colour => text()();
  IntColumn get reminderMinutesBefore => integer().nullable().customConstraint(
      'CHECK (reminder_minutes_before IS NULL OR reminder_minutes_before >= 0)')();
  TextColumn get repeatRule => text().nullable()();
  BoolColumn get isAuto => boolean()
      .customConstraint('NOT NULL DEFAULT 0 CHECK (is_auto IN (0, 1))')
      .clientDefault(() => false)();
  IntColumn get createdAt => integer().map(const EpochMsConverter())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (end_at >= start_at)'];
}

@DataClassName('Task')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title =>
      text().customConstraint('NOT NULL CHECK (length(trim(title)) > 0)')();
  TextColumn get priority => text()
      .customConstraint(
          "NOT NULL DEFAULT 'medium' CHECK (priority IN ('high', 'medium', 'low'))")
      .clientDefault(() => 'medium')
      .map(const TaskPriorityConverter())();
  IntColumn get dueAt => integer().nullable().map(const EpochMsConverter())();
  BoolColumn get isAllDay => boolean()
      .customConstraint('NOT NULL DEFAULT 0 CHECK (is_all_day IN (0, 1))')
      .clientDefault(() => false)();
  BoolColumn get isDone => boolean()
      .customConstraint('NOT NULL DEFAULT 0 CHECK (is_done IN (0, 1))')
      .clientDefault(() => false)();
  IntColumn get completedAt =>
      integer().nullable().map(const EpochMsConverter())();
  TextColumn get categoryId => text()
      .nullable()
      .customConstraint('REFERENCES categories (id) ON DELETE SET NULL')();
  TextColumn get eventId => text()
      .nullable()
      .customConstraint('REFERENCES calendar_events (id) ON DELETE SET NULL')();
  TextColumn get alarmId => text()
      .nullable()
      .customConstraint('REFERENCES alarms (id) ON DELETE SET NULL')();
  IntColumn get createdAt => integer().map(const EpochMsConverter())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints =>
      ['CHECK ((is_done = 1) = (completed_at IS NOT NULL))'];
}

@DataClassName('Note')
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()
      .customConstraint('NOT NULL REFERENCES tasks (id) ON DELETE CASCADE')();
  TextColumn get body => text()();
  IntColumn get createdAt => integer().map(const EpochMsConverter())();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InteractionLog')
class InteractionLogs extends Table {
  TextColumn get id => text()();
  TextColumn get eventType => text()
      .customConstraint("NOT NULL CHECK (event_type IN ('alarm_dismissed', "
          "'alarm_snoozed', 'challenge_completed', 'challenge_failed', "
          "'task_completed'))")
      .map(const InteractionEventTypeConverter())();
  TextColumn get alarmId => text()
      .nullable()
      .customConstraint('REFERENCES alarms (id) ON DELETE SET NULL')();
  TextColumn get taskId => text()
      .nullable()
      .customConstraint('REFERENCES tasks (id) ON DELETE SET NULL')();
  TextColumn get challengeType => text()
      .nullable()
      .customConstraint("CHECK (challenge_type IS NULL OR challenge_type IN "
          "('maths', 'memory', 'phrase', 'shake'))")
      .map(const ChallengeTypeConverter())();
  IntColumn get difficulty => integer().nullable().customConstraint(
      'CHECK (difficulty IS NULL OR difficulty BETWEEN 1 AND 5)')();
  IntColumn get durationMs => integer()
      .nullable()
      .customConstraint('CHECK (duration_ms IS NULL OR duration_ms >= 0)')();
  BoolColumn get success => boolean()
      .nullable()
      .customConstraint('CHECK (success IS NULL OR success IN (0, 1))')();
  IntColumn get createdAt => integer().map(const EpochMsConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
