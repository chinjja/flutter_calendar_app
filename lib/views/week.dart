import 'package:calendar_app/pages/day.dart';
import 'package:calendar_app/providers/week_provider.dart';
import 'package:flutter/material.dart';
import 'package:calendar_app/model/model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

typedef EventItemBuilder = Widget Function(
  BuildContext context,
  EventItem item,
  Rect bounds,
  bool more,
  int rest,
);

typedef ScrollToDate = void Function(DateTime? day);

class WeekWidget extends StatefulWidget {
  const WeekWidget({
    Key? key,
    required this.week,
    required this.callback,
  }) : super(key: key);

  final DateTime week;
  final ScrollToDate callback;

  @override
  _WeekWidgetState createState() => _WeekWidgetState();
}

class _WeekWidgetState extends State<WeekWidget> {
  late final _provider = context.read<WeekProvider>();
  late final _week = widget.week;

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
                stream: _provider.events,
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
          _pushDayPage(date);
        },
        onLongPress: () {
          _provider.plugin.newEvent(context, date);
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

  void _pushDayPage(DateTime day) async {
    final events = await _provider.rawEvents.first;
    final returnDate = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return DayPage(
            date: day,
            events: events,
          );
        },
      ),
    ) as DateTime?;
    widget.callback(returnDate);
  }
}
