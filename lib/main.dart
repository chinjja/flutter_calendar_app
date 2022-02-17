import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:flutter/material.dart';

import 'package:calendar_app/pages/routes.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  tz.initializeTimeZones();
  runApp(MultiProvider(providers: [
    Provider(create: (context) => CalendarProvider()),
  ], child: const MyApp()));
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
