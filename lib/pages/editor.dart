import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:calendar_app/main.dart';

class EventEditorPage extends StatefulWidget {
  const EventEditorPage({
    Key? key,
    this.date,
    this.event,
    this.calendar,
    this.scrollController,
  }) : super(key: key);
  final DateTime? date;
  final EventItem? event;
  final CalendarItem? calendar;
  final ScrollController? scrollController;

  @override
  _EventEditorPageState createState() => _EventEditorPageState();
}

class _EventEditorPageState extends State<EventEditorPage> {
  final _form = GlobalKey<FormState>();
  final _start = GlobalKey<FormFieldState<DateTime>>();
  final _end = GlobalKey<FormFieldState<DateTime>>();
  final _title = GlobalKey<FormFieldState<String>>();
  final _description = GlobalKey<FormFieldState<String>>();
  final _location = GlobalKey<FormFieldState<String>>();

  late Event _copy;
  late final _plugin = Provider.of<CalendarProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    if (widget.event == null) {
      _copy = Event(widget.calendar!.source.id);
    } else {
      _copy = Event.fromJson(widget.event!.source.toJson());
      _copy.start = widget.event!.source.start;
      _copy.end = widget.event!.source.end;
    }
    _copy.reminders = _copy.reminders ?? [];
    if (_copy.reminders!.isEmpty) {
      _copy.reminders!.add(Reminder(minutes: 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final allday = _copy.allDay ?? false;
    var now = DateTime.now();
    if (widget.date != null) {
      final d = widget.date!;
      now = DateTime(d.year, d.month, d.day, now.hour, now.minute);
    }
    final def = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      now.hour,
      (now.minute + 15) ~/ 15 * 15,
    );
    final start = _copy.start ?? def;
    final end = _copy.end ?? start.add(const Duration(hours: 1));

    return DefaultTextStyle(
      style: theme.textTheme.titleMedium!,
      child: SizedBox.expand(
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CloseButton(),
                      Container(
                        height: 6,
                        width: 40,
                        margin: const EdgeInsets.only(bottom: 26),
                        decoration: ShapeDecoration(
                          shape: const StadiumBorder(),
                          color: theme.dividerColor,
                        ),
                      ),
                      Material(
                        elevation: 3,
                        color: theme.primaryColor,
                        shape: const StadiumBorder(),
                        child: InkWell(
                          onTap: _save,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              'Save',
                              style: TextStyle(
                                  color: theme.colorScheme.todayTextColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 50, top: 8),
                  child: TextFormField(
                    key: _title,
                    initialValue: _copy.title,
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
                EditorTile(
                  content: DateTimeFormField(
                    fieldKey: _start,
                    allday: allday,
                    initDate: start,
                    onChanged: (value) {
                      final d = _end.currentState!.value!
                          .difference(_start.currentState!.value!);
                      _end.currentState?.didChange(value.add(d));
                    },
                  ),
                ),
                EditorTile(
                  content: DateTimeFormField(
                    fieldKey: _end,
                    allday: allday,
                    initDate: end,
                    validator: (value) {
                      if (_start.currentState!.value!.isAfter(value!)) {
                        return 'end is less than or equal to start';
                      }
                      return null;
                    },
                  ),
                ),
                EditorTile(
                  leading: const Icon(Icons.language_outlined),
                  content: Text(tz.local.name),
                ),
                EditorTile(
                  leading: const Icon(Icons.refresh_outlined),
                  content: Text('${_copy.recurrenceRule ?? 'Does not repeat'}'),
                ),
                _div(),
                StreamBuilder<Iterable<CalendarItem>>(
                    stream: _plugin.calendars,
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      if (data == null) {
                        return const SizedBox.shrink();
                      }
                      final d = data.firstWhere(
                          (element) => element.source.id == _copy.calendarId);
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
                  content: TextFormField(
                    key: _location,
                    initialValue: _copy.location,
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
                  content: TextFormField(
                    key: _description,
                    initialValue: _copy.description,
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
      ),
    );
  }

  void _save() {
    if (_form.currentState?.validate() ?? false) {
      _copy.title = _title.currentState?.value;
      _copy.location = _location.currentState?.value;
      _copy.description = _description.currentState?.value;
      _copy.start = tz.TZDateTime.from(
        _start.currentState!.value!,
        tz.local,
      );
      _copy.end = tz.TZDateTime.from(
        _end.currentState!.value!,
        tz.local,
      );
      _plugin.saveEvent(_copy);
      Navigator.pop(context);
    }
  }

  Widget _div() {
    return const Divider();
  }
}

typedef MyCallback<T> = void Function(T value);

class DateTimeFormField extends StatefulWidget {
  const DateTimeFormField({
    Key? key,
    required this.allday,
    required this.initDate,
    required this.fieldKey,
    this.validator,
    this.onChanged,
  }) : super(key: key);
  final bool allday;
  final DateTime initDate;
  final Key fieldKey;
  final FormFieldValidator<DateTime>? validator;
  final MyCallback<DateTime>? onChanged;

  @override
  State<DateTimeFormField> createState() => _DateTimeFormFieldState();
}

class _DateTimeFormFieldState extends State<DateTimeFormField> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormField<DateTime>(
      key: widget.fieldKey,
      initialValue: widget.initDate,
      validator: widget.validator,
      builder: (state) {
        final date = DateUtils.dateOnly(state.value!);
        final time = TimeOfDay.fromDateTime(state.value!);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () async {
                    final ret = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(1970, 1, 1),
                      lastDate: DateTime(2200, 1, 1),
                    );
                    if (ret != null) {
                      final newDate = ret.add(
                          Duration(hours: time.hour, minutes: time.minute));
                      widget.onChanged?.call(newDate);
                      state.didChange(newDate);
                    }
                  },
                  child: Text(DateFormat.yMd().format(date)),
                ),
                if (!widget.allday)
                  InkWell(
                    onTap: () async {
                      final ret = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (ret != null) {
                        final newDate = date.add(
                            Duration(hours: ret.hour, minutes: ret.minute));
                        widget.onChanged?.call(newDate);
                        state.didChange(newDate);
                      }
                    },
                    child: Text(time.format(context)),
                  ),
              ],
            ),
            if (state.hasError)
              Text(
                state.errorText!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                ),
              )
          ],
        );
      },
    );
  }
}

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
