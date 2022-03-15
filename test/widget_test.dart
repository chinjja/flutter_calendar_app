import 'dart:collection';

import 'package:calendar_app/main.dart';
import 'package:calendar_app/pages/month.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/views/week.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([
  DeviceCalendarPlugin,
  SharedPreferences,
])
void main() {
  testWidgets('with permission and no calendar', (tester) async {
    final plugin = MockDeviceCalendarPlugin();
    when(plugin.requestPermissions())
        .thenAnswer((_) async => Result()..data = true);
    when(plugin.hasPermissions())
        .thenAnswer((_) async => Result()..data = true);
    when(plugin.retrieveCalendars())
        .thenAnswer((_) async => Result()..data = UnmodifiableListView([]));

    final pref = MockSharedPreferences();
    when(pref.getStringList(any)).thenReturn([]);

    final widget = Provider.value(
      value: CalendarProvider(plugin: plugin, preference: pref),
      child: const MyApp(),
    );
    await tester.pumpWidget(widget);

    expect(find.byType(MonthPage), findsOneWidget);
    expect(find.byType(WeekWidget), findsWidgets);

    verify(plugin.requestPermissions()).called(1);
    verify(plugin.hasPermissions()).called(greaterThan(0));
    verify(pref.getStringList(any)).called(1);
    verify(plugin.retrieveCalendars()).called(1);
    verifyNever(plugin.retrieveEvents(any, any));
  });

  testWidgets('without permission', (tester) async {
    final plugin = MockDeviceCalendarPlugin();
    when(plugin.requestPermissions())
        .thenAnswer((_) async => Result()..data = false);
    when(plugin.hasPermissions())
        .thenAnswer((_) async => Result()..data = false);
    final pref = MockSharedPreferences();
    final widget = Provider.value(
      value: CalendarProvider(plugin: plugin, preference: pref),
      child: const MyApp(),
    );
    await tester.pumpWidget(widget);

    expect(find.byType(MonthPage), findsOneWidget);
    expect(find.byType(WeekWidget), findsWidgets);

    verify(plugin.requestPermissions()).called(1);
    verifyNever(plugin.hasPermissions());
    verifyNever(plugin.retrieveCalendars());
    verifyNever(plugin.retrieveEvents(any, any));
    verifyNever(pref.getStringList(any));
  });
}
