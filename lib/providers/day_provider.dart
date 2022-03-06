import 'dart:async';

import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:rxdart/rxdart.dart';

class DayProvider {
  DayProvider({required this.plugin, required this.date, this.seed}) {
    _subscriptions.add(plugin.eventChanged.listen((event) {
      fetchEvents();
    }));
    _subscriptions.add(plugin.calendars.listen((event) {
      fetchEvents();
    }));
  }

  void dispose() {
    for (var element in _subscriptions) {
      element.cancel();
    }
  }

  final CalendarProvider plugin;
  final DateTime date;
  final Iterable<Event>? seed;

  late final endDate = date.add(const Duration(days: 1));
  late final _subscriptions = <StreamSubscription>[];

  late final _events = BehaviorSubject.seeded(seed ?? []);
  late final events = _events.withLatestFrom(plugin.calendars, (
    Iterable<Event> events,
    Iterable<CalendarItem> calendars,
  ) {
    final ret = <EventItem>[];
    final map = <String, CalendarItem>{};
    for (final c in calendars) {
      map[c.source.id!] = c;
    }
    for (final event in events) {
      final calendar = map[event.calendarId];
      if (calendar == null || !calendar.isSelected) continue;
      if (EventUtils.isOverlappedForDay(date, event)) {
        final item = EventItem(
          event,
          calendar,
          date,
          date,
        );
        ret.add(item);
      }
    }
    return ret;
  });

  Future<void> fetchEvents() async {
    final result = await plugin.hasPermissions();
    if (!result) return;
    final data = await retrieveEvents();
    _events.add(data);
  }

  Future<Iterable<Event>> retrieveEvents() async {
    final calendars = await plugin.selectedCalendars.first;

    return await plugin.retrieveEvents(
      calendars: calendars.map((e) => e.source),
      startDate: date,
      endDate: endDate,
    );
  }
}
