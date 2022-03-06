import 'dart:math';

import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/pages/routes.dart';
import 'package:calendar_app/providers/day_provider.dart';
import 'package:calendar_app/views/timeline.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DayWidget extends StatefulWidget {
  const DayWidget({
    Key? key,
    required this.date,
  }) : super(key: key);

  final DateTime date;

  @override
  _DayWidgetState createState() => _DayWidgetState();
}

class _DayWidgetState extends State<DayWidget> {
  late final _date = widget.date;
  late final _provider = context.read<DayProvider>();
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventItem>>(
        stream: _provider.events,
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
          return Column(
            children: [
              _header(_date, alldays),
              TimelineWidget(
                date: _date,
                items: times,
              ),
            ],
          );
        });
  }

  Widget _header(DateTime date, List<EventItem> items) {
    const rowHeight = 28.0;
    final now = DateUtils.dateOnly(DateTime.now());
    final isToday = now == date;
    final hasRest = items.length > 3;
    final int n;
    if (_expanded) {
      n = max(2, items.length);
    } else if (items.length <= 2) {
      n = 2;
    } else {
      n = 3;
    }
    var height = rowHeight * n + 8;
    final alldays = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      if (!_expanded && i == 2 && items.length > 3) {
        final rest = Container(
          height: 26,
          alignment: Alignment.centerLeft,
          child: Text('+${items.length - 2}'),
        );
        alldays.add(rest);
        break;
      }
      final item = items[i];
      final widget = Padding(
        key: ValueKey(item.source.eventId),
        padding: const EdgeInsets.only(bottom: 1),
        child: Material(
          color: item.color,
          borderRadius: BorderRadius.circular(5),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, Routes.event, arguments: item);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              width: double.infinity,
              height: 27,
              child: Text(item.source.title ?? ''),
            ),
          ),
        ),
      );
      alldays.add(widget);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      clipBehavior: Clip.hardEdge,
      height: height,
      padding: const EdgeInsets.only(top: 4),
      color: Theme.of(context).secondaryHeaderColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      DateFormat.EEEE().format(date),
                      textAlign: TextAlign.center,
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isToday ? Theme.of(context).primaryColor : null,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        DateFormat.d().format(date),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: isToday ? Colors.white : null,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasRest)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                    child: SizedBox(
                      height: 26,
                      child: Icon(_expanded
                          ? Icons.expand_less_outlined
                          : Icons.expand_more_outlined),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: alldays,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
