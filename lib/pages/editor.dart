import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart';

class EventEditorPage extends StatefulWidget {
  const EventEditorPage({Key? key, this.date, this.event, this.calendar})
      : super(key: key);
  final DateTime? date;
  final EventItem? event;
  final CalendarItem? calendar;

  @override
  _EventEditorPageState createState() => _EventEditorPageState();
}

class _EventEditorPageState extends State<EventEditorPage> {
  late final _title = TextEditingController(text: _copy.title);
  late final _description = TextEditingController(text: _copy.description);
  late final _location = TextEditingController(text: _copy.location);
  late Event _copy;
  late final _plugin = Provider.of<CalendarProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    if (widget.event == null) {
      _copy = Event(widget.calendar!.source.id);
    } else {
      _copy = Event.fromJson(widget.event!.source.toJson());
    }
    _copy.reminders = _copy.reminders ?? [];
    if (_copy.reminders!.isEmpty) {
      _copy.reminders!.add(Reminder(minutes: 30));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: FlutterNativeTimezone.getLocalTimezone(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const SizedBox.shrink();
          }

          final location = getLocation(data);
          final allday = _copy.allDay ?? false;
          var now = DateTime.now();
          if (widget.date != null) {
            final d = widget.date!;
            now = DateTime(d.year, d.month, d.day, now.hour, now.minute);
          }
          final def = TZDateTime(
            location,
            now.year,
            now.month,
            now.day,
            now.hour,
            (now.minute + 7.5) ~/ 15 * 15,
          );
          final start = _copy.start ?? def;
          final end = _copy.end ?? start.add(const Duration(hours: 1));
          _copy.start = start;
          _copy.end = end;

          return DefaultTextStyle(
            style: const TextStyle(
              fontSize: 20,
              color: Colors.black,
            ),
            child: SizedBox.expand(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 50, top: 8),
                      child: TextField(
                        controller: _title,
                        decoration: const InputDecoration(
                          hintText: 'Title',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 30,
                        ),
                      ),
                    ),
                    _div(),
                    EditorTile(
                      leading: const Icon(Icons.schedule_outlined),
                      content: const Text('All-day'),
                      trailing: Switch(
                        value: allday,
                        onChanged: (v) {
                          setState(() {
                            _copy.allDay = !_copy.allDay!;
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _copy.allDay = !_copy.allDay!;
                        });
                      },
                    ),
                    _dateTime(context, start, allday, (value) {
                      setState(() {
                        final newDate = TZDateTime.from(value, location);
                        final delta = newDate.difference(start);
                        _copy.start = newDate;
                        _copy.end = _copy.end!.add(delta);
                      });
                    }),
                    _dateTime(context, end, allday, (value) {
                      setState(() {
                        _copy.end = TZDateTime.from(value, location);
                      });
                    }),
                    EditorTile(
                      leading: const Icon(Icons.language_outlined),
                      content: Text(location.name),
                    ),
                    EditorTile(
                      leading: const Icon(Icons.refresh_outlined),
                      content:
                          Text('${_copy.recurrenceRule ?? 'Does not repeat'}'),
                    ),
                    _div(),
                    StreamBuilder<Iterable<CalendarItem>>(
                        stream: _plugin.calendars,
                        builder: (context, snapshot) {
                          final data = snapshot.data;
                          if (data == null) {
                            return const SizedBox.shrink();
                          }
                          final d = data.firstWhere((element) =>
                              element.source.id == _copy.calendarId);
                          return EditorTile(
                            leading: Center(
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: d.color,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            content: Text('${d.source.name}'),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    content: SizedBox(
                                      width: 400,
                                      height: 400,
                                      child: CalendarSelectWidget(
                                        callback: (value) {
                                          setState(() {
                                            _copy.calendarId = value.source.id;
                                          });
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }),
                    _div(),
                    EditorTile(
                      leading: const Icon(Icons.location_on_outlined),
                      content: TextField(
                        controller: _location,
                        decoration: const InputDecoration(
                          hintText: 'Location',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    _div(),
                    ReminderWidget(
                        reminders: _copy.reminders!,
                        onChanged: (data) {
                          setState(() {
                            _copy.reminders = data;
                          });
                        }),
                    _div(),
                    EditorTile(
                      leading: const Icon(Icons.description_outlined),
                      content: TextField(
                        controller: _description,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Description',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    _div(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _save() {
    if (_copy.end!.isBefore(_copy.start!)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text("Invalid date")));
      return;
    }
    _copy.title = _title.text;
    _copy.location = _location.text;
    _copy.description = _description.text;
    _plugin.saveEvent(_copy);
    Navigator.pop(context);
  }

  Widget _div() {
    return const Divider(color: Colors.black);
  }

  Widget _dateTime(BuildContext context, DateTime date, bool allday,
      MyCallback<DateTime> callback) {
    return EditorTile(
      content: _date(context, date, (value) {
        callback(DateTime(
          value.year,
          value.month,
          value.day,
          date.hour,
          date.minute,
        ));
      }),
      trailing: allday
          ? null
          : _time(context, date, (value) {
              callback(DateTime(
                date.year,
                date.month,
                date.day,
                value.hour,
                value.minute,
              ));
            }),
    );
  }

  Widget _date(
    BuildContext context,
    DateTime date,
    MyCallback<DateTime> callback,
  ) {
    return GestureDetector(
      onTap: () async {
        final result = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000, 1, 1),
          lastDate: DateTime(2100, 1, 1),
        );
        if (result != null) {
          callback(result);
        }
      },
      child: Text(
        DateFormat.yMEd().format(date),
      ),
    );
  }

  Widget _time(
    BuildContext context,
    DateTime date,
    MyCallback<TimeOfDay> callback,
  ) {
    return GestureDetector(
      onTap: () async {
        final result = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(date),
        );
        if (result != null) {
          callback(result);
        }
      },
      child: Text(
        DateFormat.jm().format(date),
      ),
    );
  }
}

typedef MyCallback<T> = void Function(T value);

class AttendeeWidget extends StatelessWidget {
  const AttendeeWidget({
    Key? key,
    required this.attendees,
    required this.onChanged,
  }) : super(key: key);

  final List<Attendee?> attendees;
  final MyCallback<List<Attendee?>>? onChanged;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (int i = 0; i <= attendees.length; i++) {
      Widget? icon;
      if (i == 0) {
        icon = const Icon(Icons.people_outline);
      }
      if (i == attendees.length) {
        if (onChanged == null) {
          break;
        }
        children.add(
          EditorTile(
            leading: icon,
            content: const Text("Add"),
            onTap: () {
              final value = [...attendees];
              value.add(
                Attendee(
                  name: 'chinjja',
                  emailAddress: "chinjja.test@gmail.com",
                  role: AttendeeRole.None,
                ),
              );
              onChanged!(value);
            },
          ),
        );
      } else {
        final attendee = attendees[i];
        if (attendee != null) {
          children.add(
            EditorTile(
              leading: icon,
              content: Text('${attendee.emailAddress}'),
              trailing: onChanged == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        final value = [...attendees];
                        value.removeAt(i);
                        onChanged!(value);
                      },
                    ),
            ),
          );
        }
      }
    }
    return Column(
      children: children,
    );
  }
}

class ReminderWidget extends StatelessWidget {
  const ReminderWidget(
      {Key? key, required this.reminders, required this.onChanged})
      : super(key: key);
  final List<Reminder> reminders;
  final MyCallback<List<Reminder>>? onChanged;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (int i = 0; i <= reminders.length; i++) {
      Widget? icon;
      if (i == 0) {
        icon = const Icon(Icons.notifications_outlined);
      }
      if (i == reminders.length) {
        if (onChanged == null) {
          break;
        }
        children.add(
          EditorTile(
            leading: icon,
            content: const Text("Add notification"),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    final list = [5, 10, 15, 30, 60];
                    return AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: list
                            .map((e) => RadioListTile(
                                  title: Text('$e minutes before'),
                                  value: false,
                                  groupValue: true,
                                  onChanged: (value) {
                                    final value = [...reminders];
                                    value.add(Reminder(minutes: e));
                                    onChanged!(value);
                                    Navigator.pop(context);
                                  },
                                ))
                            .toList(),
                      ),
                    );
                  });
            },
          ),
        );
      } else {
        final reminder = reminders[i];
        children.add(
          EditorTile(
            leading: icon,
            content: Text('${reminder.minutes} minutes before'),
            trailing: onChanged == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      final value = [...reminders];
                      value.removeAt(i);
                      onChanged!(value);
                    },
                  ),
          ),
        );
      }
    }
    return Column(
      children: children,
    );
  }
}

class CalendarSelectWidget extends StatelessWidget {
  const CalendarSelectWidget({Key? key, required this.callback})
      : super(key: key);
  final MyCallback<CalendarItem> callback;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CalendarProvider>();
    return StreamBuilder<Iterable<CalendarItem>>(
      stream: provider.calendars,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        final items = data.where((element) => !element.isReadOnly).toList();

        return SizedBox(
          width: 400,
          child: ListView.builder(
            itemCount: items.length,
            itemExtent: 40,
            itemBuilder: (context, index) {
              final item = items[index];
              return EditorTile(
                leading: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                content: Text('${item.source.name}'),
                onTap: () {
                  callback(item);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class EditorTile extends StatelessWidget {
  const EditorTile({
    Key? key,
    this.onTap,
    this.leading,
    this.trailing,
    required this.content,
  }) : super(key: key);

  final GestureTapCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(children: [
            SizedBox(
              width: 40,
              child: leading,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: content,
              ),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
      ),
    );
  }
}
