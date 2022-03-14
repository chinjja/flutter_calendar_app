import 'dart:math';

import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/pages/routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayWidget extends StatefulWidget {
  const DayWidget({
    Key? key,
    required this.date,
    required this.items,
    required this.height,
  }) : super(key: key);

  final DateTime date;
  final List<EventItem> items;
  final double height;

  @override
  _DayWidgetState createState() => _DayWidgetState();
}

class _DayWidgetState extends State<DayWidget> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final date = widget.date;
    late final rowHeight = widget.height / 2;
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
    var height = rowHeight * n;
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
