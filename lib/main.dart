import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

import 'package:calendar_app/pages/routes.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  tz.initializeTimeZones();
  runApp(Provider(
      create: (context) {
        return CalendarProvider(
          DeviceCalendarPlugin(shouldInitTimezone: false),
        );
      },
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      initialRoute: Routes.month,
      routes: {
        Routes.month: (context) => const MonthPage(),
        Routes.event: (context) => const EventPage(),
      },
    );
  }
}
