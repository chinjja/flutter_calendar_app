import 'dart:developer';

import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/pages/routes.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarProvider {
  static const _selectedCalendarIds = 'selected_calendar_ids';

  CalendarProvider({required this.plugin, required this.preference});
  final DeviceCalendarPlugin plugin;
  final SharedPreferences preference;

  late final _calendars = BehaviorSubject<Iterable<CalendarItem>>();
  late final calendars = _calendars.stream;
  late final selectedCalendars =
      calendars.flatMap<Iterable<CalendarItem>>((value) {
    return Stream.fromFuture(
        Stream.fromIterable(value).where((event) => event.isSelected).toList());
  });
  late final defaultCalendar = calendars.flatMap<CalendarItem>((value) {
    return Stream.fromFuture(
        Stream.fromIterable(value).where((event) => !event.isReadOnly).first);
  });
  late final _eventChanged = PublishSubject<String>();
  late final eventChanged = _eventChanged.stream;

  Future<void> saveCalendar(Iterable<CalendarItem> item) async {
    log('save calendar');
    final data = Set<CalendarItem>.from(await calendars.first);
    data.addAll(item);
    preference.setStringList(
      _selectedCalendarIds,
      data.where((e) => e.isSelected).map((e) => e.source.id!).toList(),
    );
    _calendars.add(data);
  }

  Future<void> fetchCalendars() async {
    final result = await hasPermissions();
    if (!result) return;
    final data = await retriveCalendars();
    _calendars.add(data);
  }

  Future<List<CalendarItem>> retriveCalendars() async {
    final selected =
        Set.from(preference.getStringList(_selectedCalendarIds) ?? []);

    final list = <CalendarItem>[];
    final result = await plugin.retrieveCalendars();
    for (final c in result.data!) {
      list.add(CalendarItem(c, selected.contains(c.id)));
    }
    return list;
  }

  Future<void> saveEvent(Event event) async {
    log('save event: $event');
    final result = await plugin.createOrUpdateEvent(event);
    if (result != null) {
      if (result.isSuccess && result.data != null) {
        _eventChanged.add(result.data!);
      }
      for (final r in result.errors) {
        log(r.errorMessage);
      }
    }
  }

  Future<void> deleteEvent(Event event) async {
    log('delete event: $event');
    final result = await plugin.deleteEvent(event.calendarId, event.eventId);
    if (result.isSuccess && result.data == true) {
      _eventChanged.add(event.eventId!);
    }
    for (final r in result.errors) {
      log(r.errorMessage);
    }
  }

  Future<List<Event>> retrieveEvents({
    required Iterable<Calendar> calendars,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final list = <Event>[];
    for (final calendar in calendars) {
      final result = await plugin.retrieveEvents(
        calendar.id,
        RetrieveEventsParams(
          startDate: startDate,
          endDate: endDate,
        ),
      );
      list.addAll(result.data!);
    }
    return list;
  }

  Future<bool> hasPermissions([bool request = false]) async {
    final result = await plugin.hasPermissions();
    return result.isSuccess && result.data == true;
  }

  Future<bool> requestPermissions() async {
    final result = await plugin.requestPermissions();
    return result.isSuccess && result.data == true;
  }

  Future<void> newEvent(BuildContext context, [DateTime? date]) async {
    try {
      final defaultCalendar = await this.defaultCalendar.first;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return EventEditorPage(
              date: date,
              calendar: defaultCalendar,
            );
          },
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: Text('No default calendar'),
          );
        },
      );
    }
  }
}
