import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/providers/day_provider.dart';
import 'package:calendar_app/views/day.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class DayPage extends StatefulWidget {
  const DayPage({
    Key? key,
    required this.date,
    required this.events,
  }) : super(key: key);

  final DateTime date;
  final Iterable<Event> events;

  @override
  _DayPageState createState() => _DayPageState();
}

class _DayPageState extends State<DayPage> {
  static final firstDay = DateTime(1970, 1, 1);

  late final _dateSuject = BehaviorSubject.seeded(widget.date);

  late final _pageController = PageController(
    initialPage: _pageByDate(widget.date),
  );
  late final _localizations = MaterialLocalizations.of(context);
  late final _firstDayOffset =
      DateUtils.firstDayOffset(1970, 1, _localizations);
  late final _plugin = context.read<CalendarProvider>();

  final _bucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final date = await _dateSuject.first;
        Navigator.pop(context, date);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: StreamBuilder<DateTime>(
              stream: _dateSuject,
              builder: (context, snapshot) {
                return Text(
                    DateFormat.yMEd().format(snapshot.data ?? DateTime.now()));
              }),
          actions: [
            const IconButton(
              onPressed: null,
              icon: Icon(Icons.search),
            ),
            IconButton(
              onPressed: () {
                _goto(_pageByDate(DateTime.now()));
              },
              icon: const Icon(Icons.today),
            ),
          ],
        ),
        body: PageStorage(
          bucket: _bucket,
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, page) {
              final date = _dateByPage(page);
              return Provider<DayProvider>(
                create: (context) {
                  final provider = DayProvider(plugin: _plugin, date: date);
                  provider.fetchEvents();
                  return provider;
                },
                dispose: (context, provider) {
                  provider.dispose();
                },
                child: DayWidget(date: date),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await _plugin.newEvent(context, widget.date);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _goto(int page) {
    if ((_pageController.page! - page).abs() <= 2) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 200),
        curve: Curves.ease,
      );
    } else {
      _pageController.jumpToPage(page);
    }
  }

  int _pageByDate(DateTime dt) {
    final days = dt.difference(firstDay).inDays + _firstDayOffset;
    return days;
  }

  DateTime _dateByPage(int index) {
    return firstDay.add(Duration(days: index - _firstDayOffset));
  }
}
