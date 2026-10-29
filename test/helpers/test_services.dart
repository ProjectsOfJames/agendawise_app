import 'package:agendawise/core/database/app_database.dart';
import 'package:agendawise/core/utils/clock.dart';
import 'package:agendawise/core/utils/id_generator.dart';
import 'package:agendawise/features/alarms/application/alarm_scheduler.dart';
import 'package:agendawise/features/alarms/data/alarm_repository.dart';
import 'package:agendawise/features/calendar/data/event_repository.dart';
import 'package:agendawise/features/categories/data/category_repository.dart';
import 'package:agendawise/features/difficulty/data/interaction_logger.dart';
import 'package:agendawise/features/integration/integration_service.dart';
import 'package:agendawise/features/tasks/data/task_repository.dart';

/// Records scheduler calls so tests can check what reached the system.
class RecordingAlarmScheduler implements AlarmScheduler {
  final scheduled = <String>[];
  final cancelled = <String>[];

  @override
  Future<void> schedule(Alarm alarm) async => scheduled.add(alarm.id);

  @override
  Future<void> cancel(String alarmId) async => cancelled.add(alarmId);
}

/// Repositories and the integration service over one test database.
class TestServices {
  TestServices(this.db, Clock clock, {AlarmScheduler? scheduler})
      : scheduler = scheduler ?? RecordingAlarmScheduler() {
    const ids = IdGenerator();
    tasks = TaskRepository(db.tasksDao, db.notesDao, ids, clock);
    events = EventRepository(db.eventsDao, ids, clock);
    alarms = AlarmRepository(db, ids, clock);
    categories = CategoryRepository(db.categoriesDao, ids);
    logger = InteractionLogger(db.interactionLogsDao, ids, clock);
    integration = IntegrationService(
      database: db,
      tasks: tasks,
      events: events,
      alarms: alarms,
      categories: categories,
      alarmScheduler: this.scheduler,
      logger: logger,
      clock: clock,
    );
  }

  final AppDatabase db;
  final AlarmScheduler scheduler;
  late final TaskRepository tasks;
  late final EventRepository events;
  late final AlarmRepository alarms;
  late final CategoryRepository categories;
  late final InteractionLogger logger;
  late final IntegrationService integration;
}
