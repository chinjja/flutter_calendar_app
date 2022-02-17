import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/pages/routes.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
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

class _DayPageState extends State<DayPage> with WidgetsBindingObserver {
  static final firstDay = DateTime(1970, 1, 1);
  static const oneDay = Duration(days: 1);
  static const twoDays = Duration(days: 2);

  late final _dateSuject = BehaviorSubject.seeded(widget.date);
  late final _eventsSubject = BehaviorSubject.seeded(widget.events);
  late final _events = Rx.combineLatest3(
      _plugin.selectedCalendars, _dateSuject, _eventsSubject, (
    Iterable<CalendarItem> calendars,
    DateTime date,
    Iterable<Event> events,
  ) {
    final ret = <DateTime, List<EventItem>>{};
    final map = <String, CalendarItem>{};
    for (final c in calendars) {
      map[c.source.id!] = c;
    }
    final startDate = date.subtract(twoDays);
    final endDate = date.add(twoDays);
    for (var i = startDate; i.isBefore(endDate); i = i.add(oneDay)) {
      ret[i]?.clear();
      for (final event in events) {
        final calendar = map[event.calendarId];
        if (calendar == null) continue;
        if (EventUtils.isOverlappedForDay(i, event)) {
          final item = EventItem(
            event,
            calendar,
            i,
            i,
          );
          ret.putIfAbsent(i, () => []).add(item);
        }
      }
    }
    return ret;
  });
  late final _pageController = PageController(
    initialPage: _pageByDate(widget.date),
  );
  late final _localizations = MaterialLocalizations.of(context);
  late final _firstDayOffset =
      DateUtils.firstDayOffset(1970, 1, _localizations);
  late final _plugin = context.read<CalendarProvider>();

  final _bucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateDate();
    }
  }

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
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search),
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
          child: StreamBuilder<Map<DateTime, List<EventItem>>>(
            stream: _events,
            builder: (context, snapshot) {
              return PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  final date = _dateByPage(page);
                  _updateDate(date);
                },
                itemBuilder: (context, page) {
                  final date = _dateByPage(page);
                  final items = snapshot.data?[date] ?? [];
                  return DayWidget(date: date, events: items);
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return EventEditorPage(date: widget.date);
                },
              ),
            );
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

  Future<void> _updateDate([DateTime? d]) async {
    final date = d ?? await _dateSuject.first;
    final calendars = await _plugin.calendars.first;
    final startDate = date.subtract(twoDays);
    final endDate = date.add(twoDays);
    final events = await _plugin.retrieveEvents(
      calendars: calendars.map((e) => e.source),
      startDate: startDate,
      endDate: endDate,
    );
    _dateSuject.add(date);
    _eventsSubject.add(events);
  }

  int _pageByDate(DateTime dt) {
    final days = dt.difference(firstDay).inDays + _firstDayOffset;
    return days;
  }

  DateTime _dateByPage(int index) {
    return DateTime(1970, 1, 1).add(Duration(days: index - _firstDayOffset));
  }
}
