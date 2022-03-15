import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/pages/event.dart';
import 'package:calendar_app/pages/routes.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'colors.dart';

class TimelineWidget extends StatefulWidget {
  const TimelineWidget({
    Key? key,
    required this.date,
    required this.items,
    required this.height,
    required this.headerHeight,
  }) : super(key: key);

  final DateTime date;
  final List<EventItem> items;
  final double height;
  final double headerHeight;

  @override
  _TimelineWidgetState createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  late final _plugin = Provider.of<CalendarProvider>(context, listen: false);
  late final _rowHeight = widget.height / 24;
  late final _now =
      Stream.periodic(const Duration(seconds: 5), (_) => DateTime.now());

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final date = widget.date;
    final items = widget.items;
    return Container(
      padding: EdgeInsets.only(left: padding.left),
      height: widget.headerHeight + widget.height,
      child: Column(
        children: [
          SizedBox(
            height: widget.headerHeight,
          ),
          Stack(
            children: [
              _timelineTable(date),
              const Positioned(
                top: 0,
                bottom: 0,
                left: 71,
                child: VerticalDivider(
                  thickness: 0.5,
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 80,
                right: padding.right,
                child: _timelineItems(date, items),
              ),
              StreamBuilder<DateTime>(
                stream: _now,
                initialData: DateTime.now(),
                builder: (context, snapshot) {
                  return _timelineAt(snapshot.data!, date);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timelineAt(DateTime now, DateTime date) {
    const div = 60;
    final minutes = now.difference(date).abs().inMinutes;
    final color = Theme.of(context).colorScheme.timelineClockHand;

    if (!DateUtils.isSameDay(now, date)) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: _rowHeight * minutes / div - 5,
      left: 74,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipOval(
            child: Container(
              width: 10,
              height: 10,
              color: color,
            ),
          ),
          Expanded(
            child: Divider(
              color: color,
              thickness: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineTable(DateTime date) {
    final hours = List.generate(23, (index) => index + 1);
    const n = 24;
    return SizedBox(
        height: _rowHeight * n,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: _rowHeight / 2),
              width: 75,
              child: Column(
                children: hours.map((hour) {
                  final timeOfDay = TimeOfDay(hour: hour, minute: 0);
                  return Container(
                    padding: const EdgeInsets.only(right: 5),
                    alignment: Alignment.centerRight,
                    height: _rowHeight,
                    child: Text(timeOfDay.format(context)),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: Column(
                children: List.filled(n, 0).map((e) {
                  return Container(
                    height: _rowHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 0.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ));
  }

  Widget _timelineItems(DateTime date, List<EventItem> items) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final datas = items.map((e) => _TimelineLayoutData(date, e)).toList();
          datas.sort(
              (a, b) => a.event.source.start!.compareTo(b.event.source.start!));
          for (int i = 0; i < datas.length; i++) {
            final data = datas[i];
            if (data.cols != 0) continue;
            data.cols = 1;
            data.cols = _doLayout(datas, i, i + 1);
          }

          return DragTarget(
            onWillAccept: (data) {
              return data is EventItem && data.source.allDay == false;
            },
            onAcceptWithDetails: (details) {
              setState(() {
                final rb = context.findRenderObject() as RenderBox;
                final local = rb.globalToLocal(details.offset);
                final time = local.dy / _rowHeight;
                final d1 = (time * 60 + 7.5).toInt() ~/ 15 * 15;

                final data = details.data as EventItem;
                final start = data.source.start!;
                final end = data.source.end!;
                final d2 = start.hour * 60 + start.minute;

                final diffDays = DateUtils.dateOnly(date)
                    .difference(DateUtils.dateOnly(data.source.start!));
                data.source.start =
                    start.add(Duration(minutes: d1 - d2)).add(diffDays);
                data.source.end =
                    end.add(Duration(minutes: d1 - d2)).add(diffDays);

                _plugin.saveEvent(data.source);

                final sm = ScaffoldMessenger.of(context);
                sm.hideCurrentSnackBar();
                sm.showSnackBar(SnackBar(
                  content: Text(
                      'Moved to ${DateFormat.yMEd().add_jm().format(data.source.start!)}'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      setState(() {
                        data.source.start = start;
                        data.source.end = end;
                        _plugin.saveEvent(data.source);
                      });
                    },
                  ),
                ));
              });
            },
            builder: (context, candidateData, rejectedData) {
              return Stack(
                children: datas.map((e) {
                  const div = 60;
                  final start = e.startMinutes / div;
                  final end = e.endMinutes / div;

                  final rowWidth = width / e.cols;
                  final rowSize = Size(
                    rowWidth - 2,
                    _rowHeight * (end - start).abs() - 3,
                  );
                  return AnimatedPositioned(
                    key: ValueKey(e.event.source.eventId! +
                        e.event.source.start!.toString()),
                    duration: const Duration(milliseconds: 200),
                    top: _rowHeight * start + 1,
                    left: rowWidth * e.col,
                    child: LongPressDraggable(
                      data: e.event,
                      axis: Axis.vertical,
                      childWhenDragging: Opacity(
                        opacity: 0.6,
                        child: _eventWidget(e, rowSize),
                      ),
                      feedback: _eventWidget(
                        e,
                        Size(
                          width - 2,
                          rowSize.height,
                        ),
                        elevation: 3,
                      ),
                      dragAnchorStrategy: (draggable, dragContext, position) {
                        final renderObject =
                            context.findRenderObject()! as RenderBox;
                        final a = renderObject.globalToLocal(position);

                        final dragRenderObject =
                            dragContext.findRenderObject()! as RenderBox;
                        final b = dragRenderObject.globalToLocal(position);
                        return Offset(a.dx, b.dy);
                      },
                      child: _eventWidget(e, rowSize),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _eventWidget(_TimelineLayoutData e, Size size,
      {double elevation = 0.0}) {
    final title = e.event.source.title ?? '';

    return Material(
      color: e.event.color,
      elevation: elevation,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.event,
            arguments: e.event,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size.width,
          height: size.height,
          padding: const EdgeInsets.all(4),
          child: Text(title),
        ),
      ),
    );
  }

  int _doLayout(List<_TimelineLayoutData> list, int offset, int cur) {
    final last = list[cur - 1];
    for (int i = cur; i < list.length; i++) {
      final next = list[i];
      if (next.cols != 0) continue;
      if (!last.isConfict(next)) return last.cols;
      int idx = -1;
      final visit = {last.col};
      for (int j = i - 1; j >= offset; j--) {
        final h = list[j];
        int col = h.col;
        if (!visit.contains(col) && !h.isConfict(next)) {
          idx = col;
          break;
        } else {
          visit.add(col);
        }
      }
      if (idx == -1) {
        next.col = last.cols;
        next.cols = last.cols + 1;
      } else {
        next.col = idx;
        next.cols = last.cols;
      }
      last.cols = _doLayout(list, offset, i + 1);
    }
    return last.cols;
  }
}

class _TimelineLayoutData {
  final EventItem event;
  final DateTime date;
  int col;
  int cols;

  int get startMinutes {
    final minutes = event.source.start!.difference(date).inMinutes;
    if (minutes < 0) {
      return 0;
    }
    return minutes;
  }

  int get endMinutes {
    final minutes = event.source.end!.difference(date).inMinutes;
    if (minutes >= 24 * 60) {
      return 24 * 60;
    }
    if (minutes - startMinutes < 15) {
      return startMinutes + 15;
    }
    return minutes;
  }

  _TimelineLayoutData(this.date, this.event, [this.col = 0, this.cols = 0]);

  bool isConfict(_TimelineLayoutData other) {
    return EventUtils.isOverlapped(event.source, other.event.source);
  }
}
