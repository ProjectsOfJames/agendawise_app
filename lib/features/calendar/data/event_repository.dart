import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/events_dao.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/errors/validation_exception.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/id_generator.dart';

const defaultEventTitle = 'My event';
const defaultEventColour = '#7C5CFC';

/// Values entered on the event form.
class EventDraft {
  const EventDraft({
    required this.startAt,
    required this.endAt,
    this.title,
    this.isAllDay = false,
    this.location,
    this.colour = defaultEventColour,
    this.reminderMinutesBefore,
    this.repeatRule,
  });

  final String? title;
  final DateTime startAt;
  final DateTime endAt;
  final bool isAllDay;
  final String? location;
  final String colour;

  /// Null means no notification.
  final int? reminderMinutesBefore;

  /// iCalendar RRULE text, or null when the event does not repeat.
  final String? repeatRule;
}

class EventRepository {
  EventRepository(this._dao, this._ids, this._clock);

  final EventsDao _dao;
  final IdGenerator _ids;
  final Clock _clock;

  Stream<List<CalendarEvent>> watchOverlapping(DateTime from, DateTime to) =>
      _dao.watchOverlapping(from, to);

  Stream<List<CalendarEvent>> watchRepeating() => _dao.watchRepeating();

  Future<CalendarEvent?> getById(String id) => _dao.getById(id);

  Future<List<CalendarEvent>> getWithReminders() => _dao.getWithReminders();

  Future<String> create(EventDraft draft, {bool isAuto = false}) async {
    _checkTimes(draft);
    final id = _ids.next();
    await _dao.insertEvent(
      CalendarEventsCompanion.insert(
        id: id,
        title: Value(_titleOrDefault(draft.title)),
        startAt: draft.startAt,
        endAt: draft.endAt,
        isAllDay: Value(draft.isAllDay),
        location: Value(_blankToNull(draft.location)),
        colour: draft.colour,
        reminderMinutesBefore: Value(draft.reminderMinutesBefore),
        repeatRule: Value(_blankToNull(draft.repeatRule)),
        isAuto: Value(isAuto),
        createdAt: _clock(),
      ),
    );
    return id;
  }

  Future<void> update(String id, EventDraft draft) async {
    _checkTimes(draft);
    await _dao.updateEvent(
      id,
      CalendarEventsCompanion(
        title: Value(_titleOrDefault(draft.title)),
        startAt: Value(draft.startAt),
        endAt: Value(draft.endAt),
        isAllDay: Value(draft.isAllDay),
        location: Value(_blankToNull(draft.location)),
        colour: Value(draft.colour),
        reminderMinutesBefore: Value(draft.reminderMinutesBefore),
        repeatRule: Value(_blankToNull(draft.repeatRule)),
      ),
    );
  }

  /// A linked task keeps existing; its event link is cleared by
  /// ON DELETE SET NULL.
  Future<void> delete(String id) => _dao.deleteEvent(id);

  void _checkTimes(EventDraft draft) {
    if (draft.endAt.isBefore(draft.startAt)) {
      throw const ValidationException('An event cannot end before it starts');
    }
  }

  String _titleOrDefault(String? title) {
    final clean = title?.trim();
    return (clean == null || clean.isEmpty) ? defaultEventTitle : clean;
  }

  String? _blankToNull(String? value) {
    final clean = value?.trim();
    return (clean == null || clean.isEmpty) ? null : clean;
  }
}

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(
    ref.watch(appDatabaseProvider).eventsDao,
    ref.watch(idGeneratorProvider),
    ref.watch(clockProvider),
  ),
);
