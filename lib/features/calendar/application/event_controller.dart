import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/validation_exception.dart';
import '../../settings/data/settings_repository.dart';
import '../data/event_repository.dart';
import '../domain/repeat_rule.dart';
import 'reminder_scheduler.dart';

const customEventColoursKey = 'custom_event_colours';
const _maxCustomColours = 8;

/// Values on the event form. Times are on [date]; all-day events ignore them.
class EventForm {
  const EventForm({
    required this.date,
    this.title = '',
    this.isAllDay = false,
    this.startMinutes = 9 * 60,
    this.endMinutes = 10 * 60,
    this.location = '',
    this.reminderMinutesBefore = 10,
    this.repeat,
    required this.colourHex,
  });

  final DateTime date;
  final String title;
  final bool isAllDay;

  /// Minutes after midnight.
  final int startMinutes;
  final int endMinutes;
  final String location;

  /// Null means no notification; 0 means at the event time.
  final int? reminderMinutesBefore;
  final RepeatRule? repeat;
  final String colourHex;

  DateTime get startAt => isAllDay
      ? DateTime(date.year, date.month, date.day)
      : DateTime(date.year, date.month, date.day, 0, startMinutes);

  DateTime get endAt => isAllDay
      ? DateTime(date.year, date.month, date.day, 23, 59)
      : DateTime(date.year, date.month, date.day, 0, endMinutes);

  factory EventForm.fromEvent(CalendarEvent event) => EventForm(
        date: event.startAt,
        title: event.title,
        isAllDay: event.isAllDay,
        startMinutes: event.startAt.hour * 60 + event.startAt.minute,
        endMinutes: event.isAllDay
            ? 10 * 60
            : event.endAt.hour * 60 + event.endAt.minute,
        location: event.location ?? '',
        reminderMinutesBefore: event.reminderMinutesBefore,
        repeat: RepeatRule.tryParse(event.repeatRule),
        colourHex: event.colour,
      );

  EventDraft toDraft() {
    if (!isAllDay && endMinutes <= startMinutes) {
      throw const ValidationException('The event must end after it starts');
    }
    return EventDraft(
      title: title,
      startAt: startAt,
      endAt: endAt,
      isAllDay: isAllDay,
      location: location,
      colour: colourHex,
      reminderMinutesBefore: reminderMinutesBefore,
      repeatRule: repeat?.toRrule(),
    );
  }
}

/// Calendar event use cases.
class EventController {
  EventController(this._events, this._settings, this._reminders);

  final EventRepository _events;
  final SettingsRepository _settings;
  final ReminderScheduler _reminders;

  Future<CalendarEvent?> load(String id) => _events.getById(id);

  /// Creates the event when [id] is null, otherwise updates it.
  Future<String> save(EventForm form, {String? id}) async {
    final draft = form.toDraft();
    final eventId = id ?? await _events.create(draft);
    if (id != null) await _events.update(id, draft);

    final saved = await _events.getById(eventId);
    if (saved != null && saved.reminderMinutesBefore != null) {
      await _reminders.schedule(saved);
    } else {
      await _reminders.cancel(eventId);
    }
    return eventId;
  }

  /// A task linked to the event stays and loses its link.
  Future<void> delete(String id) async {
    await _reminders.cancel(id);
    await _events.delete(id);
  }

  Future<List<String>> customColours() async {
    final stored = await _settings.getString(customEventColoursKey);
    if (stored == null || stored.isEmpty) return const [];
    return stored.split(',');
  }

  /// Saves [hex] at the front of the custom colour list, newest first.
  Future<List<String>> addCustomColour(String hex) async {
    final colour = hex.toUpperCase();
    final colours = [
      colour,
      ...(await customColours()).where((c) => c.toUpperCase() != colour),
    ].take(_maxCustomColours).toList();
    await _settings.setString(customEventColoursKey, colours.join(','));
    return colours;
  }
}

final eventControllerProvider = Provider<EventController>(
  (ref) => EventController(
    ref.watch(eventRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
    ref.watch(reminderSchedulerProvider),
  ),
);
