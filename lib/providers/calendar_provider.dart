import 'dart:developer';

import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/pages/routes.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart';

class CalendarProvider {
  static const selectedCalendarIds = 'selected_calendar_ids';

  final _plugin = DeviceCalendarPlugin();

  late final _calendars = BehaviorSubject<Iterable<CalendarItem>>();
  late final calendars = _calendars.stream;
  late final selectedCalendars = calendars.flatMap<Iterable<CalendarItem>>(
      (value) => Stream.fromFuture(Stream.fromIterable(value)
          .where((event) => event.isSelected)
          .toList()));
  late final _eventChanged = BehaviorSubject<String>();
  late final eventChanged = _eventChanged.stream;

  Future<void> saveCalendar(Iterable<CalendarItem> item) async {
    log('save calendar');
    final pref = await SharedPreferences.getInstance();
    final data = Set<CalendarItem>.from(await calendars.first);
    data.addAll(item);
    pref.setStringList(
      selectedCalendarIds,
      data.where((e) => e.isSelected).map((e) => e.source.id!).toList(),
    );
    _calendars.add(data);
  }

  Future<void> fetchCalendars() async {
    final data = await retriveCalendars();
    _calendars.add(data);
  }

  Future<List<CalendarItem>> retriveCalendars() async {
    final pref = await SharedPreferences.getInstance();
    final selected = Set.from(pref.getStringList(selectedCalendarIds) ?? []);

    final list = <CalendarItem>[];
    final result = await _plugin.retrieveCalendars();
    for (final c in result.data!) {
      list.add(CalendarItem(c, selected.contains(c.id)));
    }
    return list;
  }

  Future<void> saveEvent(Event event) async {
    log('save event: $event');
    final result = await _plugin.createOrUpdateEvent(event);
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
    final result = await _plugin.deleteEvent(event.calendarId, event.eventId);
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
    Location? location,
  }) async {
    final loc =
        location ?? getLocation(await FlutterNativeTimezone.getLocalTimezone());
    setLocalLocation(loc);
    final list = <Event>[];
    for (final calendar in calendars) {
      final result = await _plugin.retrieveEvents(
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
    final result = await _plugin.hasPermissions();
    bool ok = result.isSuccess && result.data == true;
    if (!ok) {
      return requestPermissions();
    }
    return ok;
  }

  Future<bool> requestPermissions() async {
    final result = await _plugin.requestPermissions();
    return result.isSuccess && result.data == true;
  }

  Future<void> newEvent(BuildContext context, [DateTime? date]) async {
    final calendars = await this.calendars.first;
    try {
      final defaultCalendar = calendars
          .where((element) => element.isSelected && !element.isReadOnly)
          .first;
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
