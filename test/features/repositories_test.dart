import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/core/domain/challenge_type.dart';
import 'package:agendawise/core/domain/task_priority.dart';
import 'package:agendawise/core/errors/validation_exception.dart';
import 'package:agendawise/core/utils/id_generator.dart';
import 'package:agendawise/features/account/data/user_repository.dart';
import 'package:agendawise/features/alarms/data/alarm_repository.dart';
import 'package:agendawise/features/calendar/data/event_repository.dart';
import 'package:agendawise/features/categories/data/category_repository.dart';
import 'package:agendawise/features/settings/data/settings_repository.dart';
import 'package:agendawise/features/tasks/data/task_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SteppingClock clock;
  const ids = IdGenerator();

  setUp(() {
    db = openTestDatabase();
    clock = SteppingClock();
  });
  tearDown(() => db.close());

  final invalid = throwsA(isA<ValidationException>());

  group('AlarmRepository', () {
    late AlarmRepository alarms;
    setUp(() => alarms = AlarmRepository(db, ids, clock.call));

    test('new challenge starts at level 2', () async {
      final id = await alarms.create(
        const AlarmDraft(hour: 6, minute: 30, challengeType: ChallengeType.maths),
      );
      final saved = await alarms.getById(id);
      expect(saved!.alarm.hour, 6);
      expect(saved.challenge!.challengeType, ChallengeType.maths);
      expect(saved.challenge!.difficulty, initialChallengeDifficulty);
    });

    test('blank label is stored as null', () async {
      final id = await alarms.create(
        const AlarmDraft(hour: 7, minute: 0, title: '  '),
      );
      expect((await alarms.getById(id))!.alarm.title, isNull);
    });

    test('update keeps difficulty for the same type and resets on change',
        () async {
      const draft =
          AlarmDraft(hour: 6, minute: 0, challengeType: ChallengeType.memory);
      final id = await alarms.create(draft);
      await alarms.setChallengeDifficulty(id, 4);

      await alarms.update(id, draft);
      expect((await alarms.getById(id))!.challenge!.difficulty, 4);

      await alarms.update(
        id,
        const AlarmDraft(hour: 6, minute: 0, challengeType: ChallengeType.shake),
      );
      final changed = (await alarms.getById(id))!.challenge!;
      expect(changed.challengeType, ChallengeType.shake);
      expect(changed.difficulty, initialChallengeDifficulty);

      await alarms.update(id, const AlarmDraft(hour: 6, minute: 0));
      expect((await alarms.getById(id))!.challenge, isNull);
    });

    test('difficulty is clamped to 1..5', () async {
      final id = await alarms.create(
        const AlarmDraft(hour: 6, minute: 0, challengeType: ChallengeType.phrase),
      );
      await alarms.setChallengeDifficulty(id, 9);
      expect((await alarms.getById(id))!.challenge!.difficulty, 5);
    });

    test('list is ordered by time and active filter works', () async {
      await alarms.create(const AlarmDraft(hour: 9, minute: 0));
      final early = await alarms.create(const AlarmDraft(hour: 5, minute: 45));
      await alarms.setActive(early, false);

      final all = await alarms.watchAll().first;
      expect(all.map((a) => a.alarm.hour), [5, 9]);
      expect((await alarms.getActive()).map((a) => a.hour), [9]);
    });
  });

  group('TaskRepository', () {
    late TaskRepository tasks;
    setUp(() => tasks = TaskRepository(db.tasksDao, db.notesDao, ids, clock.call));

    test('blank title is rejected', () async {
      await expectLater(tasks.create(const TaskDraft(title: '  ')), invalid);
    });

    test('default priority is medium', () async {
      final id = await tasks.create(const TaskDraft(title: 'Report'));
      expect((await tasks.getById(id))!.priority, TaskPriority.medium);
    });

    test('open tasks: dated first by due time, then undated', () async {
      await tasks.create(const TaskDraft(title: 'Undated'));
      await tasks.create(
        TaskDraft(title: 'Later', dueAt: DateTime(2026, 11, 3, 9)),
      );
      await tasks.create(
        TaskDraft(title: 'Sooner', dueAt: DateTime(2026, 11, 2, 9)),
      );
      final open = await tasks.watchOpen().first;
      expect(open.map((t) => t.title), ['Sooner', 'Later', 'Undated']);
    });

    test('setDone moves a task between lists and back', () async {
      final id = await tasks.create(const TaskDraft(title: 'Report'));

      await tasks.setDone(id, true);
      final done = await tasks.getById(id);
      expect(done!.isDone, isTrue);
      expect(done.completedAt, isNotNull);
      expect(await tasks.watchOpen().first, isEmpty);
      expect(await tasks.watchCompleted().first, hasLength(1));

      await tasks.setDone(id, false);
      final reopened = await tasks.getById(id);
      expect(reopened!.isDone, isFalse);
      expect(reopened.completedAt, isNull);
    });

    test('all-day flag is only kept with a due date', () async {
      final id = await tasks.create(
        const TaskDraft(title: 'No date', isAllDay: true),
      );
      expect((await tasks.getById(id))!.isAllDay, isFalse);
    });

    test('notes are added in order and removed with the task', () async {
      final id = await tasks.create(const TaskDraft(title: 'Report'));
      await tasks.addNote(id, 'First');
      await tasks.addNote(id, 'Second');
      expect((await tasks.getNotes(id)).map((n) => n.body), ['First', 'Second']);

      await tasks.delete(id);
      expect(await db.select(db.notes).get(), isEmpty);
    });

    test('setLinks updates only the given links', () async {
      final events = EventRepository(db.eventsDao, ids, clock.call);
      final eventId = await events.create(
        EventDraft(
          startAt: DateTime(2026, 11, 2, 9),
          endAt: DateTime(2026, 11, 2, 10),
        ),
        isAuto: true,
      );
      final id = await tasks.create(const TaskDraft(title: 'Report'));

      await tasks.setLinks(id, eventId: Value(eventId));
      expect((await tasks.getById(id))!.eventId, eventId);
      expect((await tasks.getByEventId(eventId))!.id, id);

      await tasks.setLinks(id, alarmId: const Value(null));
      expect((await tasks.getById(id))!.eventId, eventId);
    });
  });

  group('EventRepository', () {
    late EventRepository events;
    setUp(() => events = EventRepository(db.eventsDao, ids, clock.call));

    test('empty title becomes "My event"', () async {
      final id = await events.create(
        EventDraft(
          title: ' ',
          startAt: DateTime(2026, 11, 2, 9),
          endAt: DateTime(2026, 11, 2, 10),
        ),
      );
      expect((await events.getById(id))!.title, defaultEventTitle);
    });

    test('end before start is rejected', () async {
      await expectLater(
        events.create(
          EventDraft(
            startAt: DateTime(2026, 11, 2, 10),
            endAt: DateTime(2026, 11, 2, 9),
          ),
        ),
        invalid,
      );
    });

    test('overlap query returns events touching the range', () async {
      await events.create(
        EventDraft(
          title: 'Inside',
          startAt: DateTime(2026, 11, 2, 9),
          endAt: DateTime(2026, 11, 2, 10),
        ),
      );
      await events.create(
        EventDraft(
          title: 'Spanning',
          startAt: DateTime(2026, 11, 1, 22),
          endAt: DateTime(2026, 11, 2, 1),
        ),
      );
      await events.create(
        EventDraft(
          title: 'Next day',
          startAt: DateTime(2026, 11, 3, 9),
          endAt: DateTime(2026, 11, 3, 10),
        ),
      );
      final day = await events
          .watchOverlapping(DateTime(2026, 11, 2), DateTime(2026, 11, 3))
          .first;
      expect(day.map((e) => e.title), ['Spanning', 'Inside']);
    });
  });

  group('CategoryRepository', () {
    late CategoryRepository categories;
    setUp(() => categories = CategoryRepository(db.categoriesDao, ids));

    test('duplicate name ignoring case is rejected', () async {
      await categories.create(name: 'Work', colour: '#06B6D4');
      await expectLater(
        categories.create(name: ' work ', colour: '#F97316'),
        invalid,
      );
    });

    test('renaming to its own name is allowed', () async {
      final id = await categories.create(name: 'Work', colour: '#06B6D4');
      await categories.update(id, name: 'WORK', colour: '#06B6D4');
      expect((await categories.getById(id))!.name, 'WORK');
    });

    test('invalid colour is rejected', () async {
      await expectLater(
        categories.create(name: 'Home', colour: '06B6D4'),
        invalid,
      );
    });
  });

  group('SettingsRepository', () {
    test('values round-trip and can be removed', () async {
      final settings = SettingsRepository(db.settingsDao);
      await settings.setString(SettingsKeys.themeMode, 'dark');
      expect(await settings.getString(SettingsKeys.themeMode), 'dark');

      await settings.setString(SettingsKeys.themeMode, 'light');
      expect(await settings.getString(SettingsKeys.themeMode), 'light');

      await settings.remove(SettingsKeys.themeMode);
      expect(await settings.getString(SettingsKeys.themeMode), isNull);
    });
  });

  group('UserRepository', () {
    test('caches one profile and replaces it for another account', () async {
      final users = UserRepository(db.usersDao, clock.call);
      await users.cacheProfile(
          uid: 'a', fullName: 'Thandi', email: 'thandi@example.com');
      await users.updateImagePath('a', '/pics/a.jpg');

      await users.cacheProfile(
          uid: 'a', fullName: 'Thandi N', email: 'thandi@example.com');
      var cached = (await users.getCached())!;
      expect(cached.fullName, 'Thandi N');
      expect(cached.imagePath, '/pics/a.jpg');
      expect(cached.passwordHash, isEmpty);

      await users.cacheProfile(
          uid: 'b', fullName: 'Sipho', email: 'sipho@example.com');
      cached = (await users.getCached())!;
      expect(cached.id, 'b');
      expect(cached.imagePath, isNull);
      expect(await db.select(db.users).get(), hasLength(1));
    });
  });
}
