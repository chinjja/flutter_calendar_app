import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

class EventItem implements Comparable<EventItem> {
  final Event source;
  final CalendarItem calendar;
  final DateTime startDate;
  final DateTime endDate;
  const EventItem(this.source, this.calendar, this.startDate, this.endDate);

  Color get color {
    return Color(calendar.source.color ?? 0);
  }

  int get length {
    return endDate.difference(startDate).inDays;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventItem && source.eventId == other.source.eventId;

  @override
  int get hashCode => source.eventId.hashCode;

  @override
  int compareTo(EventItem other) {
    return other.length - length;
  }
}

class CalendarItem {
  final Calendar source;
  bool isSelected;
  bool get isReadOnly => source.isReadOnly ?? true;

  CalendarItem(
    this.source, [
    this.isSelected = false,
  ]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarItem && source.id == other.source.id;

  @override
  int get hashCode => source.id.hashCode;
}

class EventUtils {
  static bool isOverlapped(Event a, Event b) {
    return a.start!.isBefore(b.end!) && a.end!.isAfter(b.start!);
  }

  static bool isOverlappedForDay(DateTime date, Event event) {
    if (event.allDay!) {
      return event.start!.compareTo(date) <= 0 &&
          date.compareTo(event.end!) <= 0;
    }
    return date.isBefore(event.end!) &&
        date.add(const Duration(days: 1)).isAfter(event.start!);
  }
}
