import 'dart:developer';

import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

import 'package:calendar_app/pages/routes.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';

export 'views/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  final loc = getLocation(await FlutterNativeTimezone.getLocalTimezone());
  log(loc.name);
  setLocalLocation(loc);

  final pref = await SharedPreferences.getInstance();
  runApp(Provider(
      create: (context) {
        return CalendarProvider(
          plugin: DeviceCalendarPlugin(shouldInitTimezone: false),
          preference: pref,
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
        dividerColor: Colors.grey,
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
