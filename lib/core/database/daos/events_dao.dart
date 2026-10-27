import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'events_dao.g.dart';

@DriftAccessor(tables: [CalendarEvents])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(super.attachedDatabase);

  /// Events that overlap the half-open range [from, to).
  Stream<List<CalendarEvent>> watchOverlapping(DateTime from, DateTime to) =>
      (select(calendarEvents)
            ..where((e) =>
                e.startAt.isSmallerThanValue(to.millisecondsSinceEpoch) &
                e.endAt.isBiggerOrEqualValue(from.millisecondsSinceEpoch))
            ..orderBy([(e) => OrderingTerm.asc(e.startAt)]))
          .watch();

  /// Events with a repeat rule, which may produce occurrences in any range.
  Stream<List<CalendarEvent>> watchRepeating() =>
      (select(calendarEvents)..where((e) => e.repeatRule.isNotNull())).watch();

  Future<CalendarEvent?> getById(String id) =>
      (select(calendarEvents)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<List<CalendarEvent>> getWithReminders() => (select(calendarEvents)
        ..where((e) => e.reminderMinutesBefore.isNotNull()))
      .get();

  Future<void> insertEvent(CalendarEventsCompanion event) =>
      into(calendarEvents).insert(event);

  Future<int> updateEvent(String id, CalendarEventsCompanion changes) =>
      (update(calendarEvents)..where((e) => e.id.equals(id))).write(changes);

  Future<int> deleteEvent(String id) =>
      (delete(calendarEvents)..where((e) => e.id.equals(id))).go();
}
