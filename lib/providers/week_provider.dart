import 'dart:async';

import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class WeekProvider {
  WeekProvider({required this.plugin, required this.week}) {
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
  final DateTime week;

  late final _subscriptions = <StreamSubscription>[];

  late final endWeek = week.add(const Duration(days: 7));
  late final _events = BehaviorSubject<Iterable<Event>>();

  late final rawEvents = _events.stream;
  late final events = _events.withLatestFrom(plugin.selectedCalendars,
      (Iterable<Event> events, Iterable<CalendarItem> calendars) {
    final _calendars = <String, CalendarItem>{};
    for (final c in calendars) {
      _calendars[c.source.id!] = c;
    }
    final map = <DateTime, Set<EventItem>>{};
    for (final event in events) {
      final start = DateUtils.dateOnly(event.start!);
      final end = DateUtils.dateOnly(event.end!).add(const Duration(days: 1));
      final calendar = _calendars[event.calendarId];
      if (calendar != null && calendar.isSelected) {
        final item = EventItem(
          event,
          calendar,
          EventUtils.maxItem(start, week),
          EventUtils.minItem(endWeek, end),
        );
        map.putIfAbsent(EventUtils.maxItem(start, week), () => {}).add(item);
      }
    }
    return map;
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
      startDate: week,
      endDate: endWeek,
    );
  }
}
