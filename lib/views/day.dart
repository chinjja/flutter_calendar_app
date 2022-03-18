import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/pages/routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'colors.dart';

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
  late final _now =
      Stream.periodic(const Duration(seconds: 5), (_) => DateTime.now());

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return StreamBuilder<DateTime>(
        stream: _now,
        initialData: DateTime.now(),
        builder: (context, snapshot) {
          final theme = Theme.of(context);
          final items = widget.items;
          final date = widget.date;
          late final rowHeight = (widget.height - 12) / 2;
          final now = snapshot.data!;
          final isToday = DateUtils.isSameDay(now, date);
          return Container(
            height: widget.height,
            padding: const EdgeInsets.only(top: 4),
            color: theme.secondaryHeaderColor,
            child: Padding(
              padding:
                  EdgeInsets.only(left: padding.left, right: padding.right),
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
                            const SizedBox(height: 4),
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isToday
                                    ? Theme.of(context).primaryColor
                                    : null,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                DateFormat.d().format(date),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: isToday
                                      ? theme.colorScheme.todayTextColor
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children:
                          items.map((e) => _allday(e, rowHeight)).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _allday(EventItem item, double rowHeight) {
    return Container(
      height: rowHeight,
      constraints: const BoxConstraints(minWidth: 50),
      child: Material(
        color: item.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: InkWell(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: Text(
                item.source.title ?? '',
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              Routes.event,
              arguments: item,
            );
          },
        ),
      ),
    );
  }
}
