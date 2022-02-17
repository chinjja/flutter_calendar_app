import 'dart:async';

import 'package:calendar_app/pages/routes.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/pages/day.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/views/calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class MonthPage extends StatefulWidget {
  const MonthPage({Key? key}) : super(key: key);

  @override
  _MonthPageState createState() => _MonthPageState();
}

class _MonthPageState extends State<MonthPage> with WidgetsBindingObserver {
  static const dayInMillis = 24 * 60 * 60 * 1000;
  static const _rowHeight = 120.0;
  static final firstDay = DateTime(1970, 1, 1);

  late final _plugin = context.read<CalendarProvider>();
  late final _localizations = MaterialLocalizations.of(context);
  late final firstDayOffset = DateUtils.firstDayOffset(1970, 1, _localizations);

  late final _title = BehaviorSubject.seeded(getIndexByDate(DateTime.now()));

  ScrollController? _controller;
  late var _index = getIndexByDate(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _controller = ScrollController(
        initialScrollOffset: getOffsetByDate(DateTime.now()),
      );
      _controller!.addListener(() async {
        final index = getIndexByOffset(_controller!.offset);
        if (_index != index) {
          _index = index;
          _title.add(index);
        }
      });
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
        final result = await _plugin.requestPermissions();
        if (result) {
          _fetchCalendars();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _fetchCalendars();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final yoils =
        List.generate(7, (index) => firstDay.add(Duration(days: index)));
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<int>(
          stream: _title,
          builder: (context, snapshot) {
            final index = snapshot.data;
            if (index == null) return const CircularProgressIndicator();
            final startDay = getDateByIndex(index);
            final title = DateFormat.yMMMM()
                .format(startDay.add(const Duration(days: 3)));
            return Text(title);
          },
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              _scrollToByDate(DateTime.now());
            },
            icon: const Icon(Icons.today),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 26,
            decoration: BoxDecoration(
              color: theme.primaryColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: yoils
                  .map(
                    (e) => Expanded(
                      child: Text(
                        DateFormat.E().format(e),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _controller,
                  itemExtent: _rowHeight,
                  itemBuilder: (context, index) {
                    final date = getDateByIndex(index);
                    return WeekWidget(
                      week: date,
                      onTapDay: (day, events) async {
                        final returnDate = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return StreamBuilder<Map<String, Calendar>>(
                                stream: _plugin.selectedCalendars.map((event) {
                                  final map = <String, Calendar>{};
                                  for (final c in event) {
                                    map[c.source.id!] = c.source;
                                  }
                                  return map;
                                }),
                                builder: (context, snapshot) {
                                  final data = snapshot.data;
                                  if (data == null) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  return DayPage(
                                    date: day,
                                    events: events,
                                  );
                                },
                              );
                            },
                          ),
                        ) as DateTime?;
                        if (returnDate != null) {
                          final offset = getOffsetByDate(returnDate);
                          final height =
                              context.findRenderObject()!.semanticBounds.height;
                          final curr = _controller?.offset ?? 0;
                          if (offset < curr ||
                              offset >
                                  curr +
                                      _rowHeight * (height ~/ _rowHeight - 1)) {
                            _scrollToByDate(returnDate);
                          } else {
                            final n = height ~/ _rowHeight - 2;
                            final h = _rowHeight * n;
                            if (offset > curr + h) {
                              _scrollToByIndex(getIndexByDate(returnDate) - n);
                            }
                          }
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const EventEditorPage();
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      drawer: const Drawer(
        child: CalendarWidget(),
      ),
    );
  }

  void _fetchCalendars() async {
    final result = await _plugin.hasPermissions();
    if (!result) return;
    await _plugin.fetchCalendars();
  }

  void _goto() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: getDateByIndex(_index),
      firstDate: DateTime(1971),
      lastDate: DateTime(2200),
    );
    if (dt != null) {
      _scrollToByDate(dt);
    }
  }

  void _scrollToByDate(DateTime to, [bool animate = true]) {
    final index = getIndexByDate(to);
    _scrollToByIndex(index, animate);
  }

  void _scrollToByIndex(int index, [bool animate = true]) {
    final offset = getOffsetByIndex(index);
    if (animate && (_index - index).abs() < 10) {
      _controller?.animateTo(
        offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    } else {
      _controller?.jumpTo(offset);
    }
  }

  int getIndexByDate(DateTime dt) {
    final days = dt.difference(firstDay).inDays + firstDayOffset;
    return days ~/ 7;
  }

  int getIndexByOffset(double offset) {
    return offset ~/ _rowHeight;
  }

  double getOffsetByDate(DateTime dt) {
    return getOffsetByIndex(getIndexByDate(dt));
  }

  double getOffsetByIndex(int index) {
    return index * _rowHeight;
  }

  DateTime getDateByIndex(int index) {
    return getDateByOffset(getOffsetByIndex(index));
  }

  DateTime getDateByOffset(double offset) {
    final index = getIndexByOffset(offset);
    final dt = DateTime.fromMillisecondsSinceEpoch(
      (dayInMillis * index * 7).toInt(),
    );
    return DateUtils.dateOnly(dt.subtract(Duration(days: firstDayOffset)));
  }
}

typedef EventItemBuilder = Widget Function(
  BuildContext context,
  EventItem item,
  Rect bounds,
  bool more,
  int rest,
);

T maxItem<T extends Comparable>(T a, T b) {
  if (a.compareTo(b) >= 0) return a;
  return b;
}

T minItem<T extends Comparable>(T a, T b) {
  if (a.compareTo(b) <= 0) return a;
  return b;
}

typedef OnTapDay = void Function(DateTime day, Iterable<Event> events);

class WeekWidget extends StatefulWidget {
  const WeekWidget({
    Key? key,
    required this.week,
    required this.onTapDay,
  }) : super(key: key);

  final DateTime week;
  final OnTapDay onTapDay;
  @override
  _WeekWidgetState createState() => _WeekWidgetState();
}

class _WeekWidgetState extends State<WeekWidget> with WidgetsBindingObserver {
  late final _plugin = context.read<CalendarProvider>();
  late final _week = widget.week;
  late final _endWeek = _week.add(const Duration(days: 7));
  late final _events = BehaviorSubject<Iterable<Event>>();
  late final _stream = Rx.combineLatest2(_events, _plugin.selectedCalendars,
      (Iterable<Event> events, Iterable<CalendarItem> calendars) {
    final _calendars = <String, CalendarItem>{};
    for (final c in calendars) {
      _calendars[c.source.id!] = c;
    }
    final map = <DateTime, Set<EventItem>>{};
    for (final event in events) {
      final start = DateUtils.dateOnly(event.start!);
      final end = DateUtils.dateOnly(event.end!).add(const Duration(days: 1));
      final calendar = _calendars[event.calendarId];
      if (calendar != null) {
        final item = EventItem(
          event,
          calendar,
          maxItem(start, _week),
          minItem(_endWeek, end),
        );
        map.putIfAbsent(maxItem(start, _week), () => {}).add(item);
      }
    }
    return map;
  });

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _fetchEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _day(now, _week),
            _day(now, _week.add(const Duration(days: 1))),
            _day(now, _week.add(const Duration(days: 2))),
            _day(now, _week.add(const Duration(days: 3))),
            _day(now, _week.add(const Duration(days: 4))),
            _day(now, _week.add(const Duration(days: 5))),
            _day(now, _week.add(const Duration(days: 6))),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            const offset = 16;
            final width = constraints.maxWidth / 7;
            final height = (constraints.maxHeight - offset) / 6;
            return IgnorePointer(
              child: StreamBuilder<Map<DateTime, Set<EventItem>>>(
                stream: _stream,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  if (data == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return Stack(
                    children: _buildEvents(
                      context: context,
                      map: data,
                      builder: (context, item, bounds, more, rest) {
                        final bk = item.color;
                        const textStyle = TextStyle(
                          fontSize: 12,
                        );
                        Widget child;
                        if (more) {
                          child = Container(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            alignment: Alignment.centerLeft,
                            width: width * bounds.width,
                            height: height * bounds.height - 1,
                            child: Text(
                              '+$rest',
                              style: textStyle,
                            ),
                          );
                        } else {
                          child = Ink(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            width: width * bounds.width - 2,
                            height: height * bounds.height - 1,
                            decoration: BoxDecoration(
                              color: bk,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(5),
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.source.title ?? '',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: textStyle,
                              ),
                            ),
                          );
                        }
                        return Positioned(
                          key: ValueKey(item.source.eventId),
                          top: height * bounds.top + offset,
                          left: width * bounds.left + 1,
                          child: child,
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildEvents({
    required BuildContext context,
    required Map<DateTime, Set<EventItem>> map,
    required EventItemBuilder builder,
  }) {
    final arr = List.generate(6, (i) => List.generate(7, (j) => false));
    final keys = map.keys.toList();
    keys.sort();

    List<Widget> widgets = [];
    for (final date in keys) {
      final list = map[date]!.toList();
      list.sort();
      int x = _week.difference(date).inDays.abs();
      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        int length = item.length;
        if (length <= 0) continue;

        for (int y = 0; y < arr.length; y++) {
          if (arr[y][x]) continue;
          for (int col = 0; col < length; col++) {
            arr[y][col + x] = true;
          }
          widgets.add(
            builder(
              context,
              item,
              Rect.fromLTWH(
                x.toDouble(),
                y.toDouble(),
                length.toDouble(),
                1.0,
              ),
              y == arr.length - 1 && i < list.length - 1,
              list.length - i,
            ),
          );
          break;
        }
      }
    }
    return widgets;
  }

  Widget _day(DateTime now, DateTime date) {
    final theme = Theme.of(context);
    Color? bk;
    if (date.month % 2 == 0) {
      bk = theme.secondaryHeaderColor;
    }
    Color? todayBk;
    Color? todayFk;
    if (DateUtils.isSameDay(now, date)) {
      todayBk = theme.primaryColor;
      todayFk = Colors.white;
    }

    return Expanded(
      key: ValueKey(date),
      child: InkWell(
        onTap: () async {
          final events = await _events.first;
          widget.onTapDay(date, events);
        },
        child: Ink(
          padding: const EdgeInsets.only(
            top: 1,
            left: 1,
            right: 1,
          ),
          decoration: BoxDecoration(
            color: bk,
            border: Border.all(
              color: Colors.grey,
              width: 0.25,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Ink(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(5),
                  ),
                  color: todayBk,
                ),
                child: Text(
                  DateFormat.Md().format(date),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: todayFk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchEvents() async {
    final result = await _plugin.hasPermissions();
    if (!result) return;

    final calendars = await _plugin.selectedCalendars.first;

    final data = await _plugin.retrieveEvents(
      calendars: calendars.map((e) => e.source),
      startDate: _week,
      endDate: _week.add(const Duration(days: 7)),
    );
    _events.add(data);
  }
}
