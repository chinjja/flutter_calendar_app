import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/providers/day_provider.dart';
import 'package:calendar_app/views/day.dart';
import 'package:calendar_app/views/timeline.dart';
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

class _DayPageState extends State<DayPage> with SingleTickerProviderStateMixin {
  static final firstDay = DateTime(1970, 1, 1);

  late final _dateSuject = BehaviorSubject.seeded(widget.date);
  late final _scrollController = ScrollController(
    initialScrollOffset: _offsetByDate(widget.date),
  );

  late final _plugin = context.read<CalendarProvider>();

  static const _headerExtent = 68.0;
  static const _minItemExtent = 34.0 * 24;
  static const _maxItemExtent = 200.0 * 24;

  double _itemExtent = _minItemExtent;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _dateSuject.add(_dateByOffset(_scrollController.offset));
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dateSuject.close();
    super.dispose();
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
              onPressed: _moveTo,
              icon: const Icon(Icons.search),
            ),
            IconButton(
              onPressed: _today,
              icon: const Icon(Icons.today),
            ),
          ],
        ),
        body: ListView.builder(
          controller: _scrollController,
          itemExtent: _itemExtent,
          itemBuilder: (context, index) {
            final date = _dateByIndex(index);
            return Provider<DayProvider>(
              create: (context) {
                return DayProvider(plugin: _plugin, date: date);
              },
              dispose: (context, provider) {
                provider.dispose();
              },
              builder: (context, child) {
                var offset = _scrollController.offset - _offsetByIndex(index);
                if (offset > _itemExtent - _headerExtent) {
                  offset = _itemExtent - _headerExtent;
                }
                if (offset < 0) {
                  offset = 0;
                }
                final provider = Provider.of<DayProvider>(context);
                return StreamBuilder<List<EventItem>>(
                  stream: provider.events,
                  builder: (context, snapshot) {
                    final events = snapshot.data ?? [];
                    final alldays = <EventItem>[];
                    final times = <EventItem>[];
                    for (final item in events) {
                      if (item.source.allDay ?? false) {
                        alldays.add(item);
                      } else {
                        times.add(item);
                      }
                    }
                    return Stack(
                      children: [
                        TimelineWidget(
                          date: date,
                          items: times,
                          height: _itemExtent - _headerExtent,
                          headerHeight: _headerExtent,
                        ),
                        Positioned(
                          top: offset,
                          left: 0,
                          right: 0,
                          child: DayWidget(
                            date: date,
                            items: alldays,
                            height: _headerExtent,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final date = await _dateSuject.first;
            await _plugin.newEvent(context, date);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _moveTo() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _dateByOffset(_scrollController.offset),
      firstDate: DateTime(1971),
      lastDate: DateTime(2200),
    );
    if (dt != null) {
      _goto(_indexByDate(dt));
    }
  }

  void _today() {
    final now = DateTime.now();
    _goto(_indexByDate(now), TimeOfDay.fromDateTime(now));
  }

  void _goto(
    int index, [
    TimeOfDay time = const TimeOfDay(hour: 5, minute: 0),
  ]) {
    final offset = _offsetByIndex(index) + _offsetByTime(time);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
    );
  }

  double _offsetByTime(TimeOfDay? time) {
    if (time == null) {
      return 0;
    }
    return (_itemExtent - _headerExtent) * (time.hour / 24);
  }

  double _offsetByIndex(int index) {
    return _itemExtent * index;
  }

  DateTime _dateByIndex(int index) {
    return firstDay.add(Duration(days: index));
  }

  int _indexByOffset(double offset) {
    return offset ~/ _itemExtent;
  }

  DateTime _dateByOffset(double offset) {
    return _dateByIndex(_indexByOffset(offset));
  }

  int _indexByDate(DateTime dt) {
    final d = dt.difference(firstDay);
    return d.inDays;
  }

  double _offsetByDate(DateTime dt) {
    return _offsetByIndex(_indexByDate(dt));
  }
}
