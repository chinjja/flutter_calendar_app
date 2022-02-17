import 'package:calendar_app/model/model.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart';

class CalendarProvider {
  static const selectedCalendarIds = 'selected_calendar_ids';

  final plugin = DeviceCalendarPlugin();

  late final _calendars = BehaviorSubject<Iterable<CalendarItem>>();
  late final calendars = _calendars.stream;
  late final selectedCalendars =
      calendars.map((e) => e.where((c) => c.isSelected).toList());

  late final _events = BehaviorSubject<Iterable<Event>>();
  late final events = _events.stream;

  Future<void> updateCalendar(Iterable<CalendarItem> item) async {
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
    final result = await plugin.retrieveCalendars();
    for (final c in result.data!) {
      list.add(CalendarItem(c, selected.contains(c.id)));
    }
    return list;
  }

  Future<void> fetchEvents({
    required Iterable<Calendar> calendars,
    required DateTime startDate,
    required DateTime endDate,
    Location? location,
  }) async {
    final data = await retrieveEvents(
      calendars: calendars,
      startDate: startDate,
      endDate: endDate,
      location: location,
    );
    _events.add(data);
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
    bool ok = result.isSuccess && result.data == true;
    if (!ok) {
      return requestPermissions();
    }
    return ok;
  }

  Future<bool> requestPermissions() async {
    final result = await plugin.requestPermissions();
    return result.isSuccess && result.data == true;
  }
}
