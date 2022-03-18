import 'dart:developer';

import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
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
  final _attendees = GlobalKey<FormFieldState<List<Attendee>>>();
  final _reminder = GlobalKey<FormFieldState<List<Reminder>>>();
  final _calendar = GlobalKey<FormFieldState<CalendarItem>>();

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

    return SafeArea(
      child: DefaultTextStyle(
        style: theme.textTheme.titleMedium!,
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
                AttendeeFormField(
                  attendees: _copy.attendees
                          ?.where((e) => e != null)
                          .map((e) => e!)
                          .toList() ??
                      [],
                  fieldKey: _attendees,
                  editMode: true,
                ),
                _div(),
                StreamBuilder<CalendarItem>(
                    stream: _plugin.defaultCalendar,
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      if (data == null) {
                        return const SizedBox.shrink();
                      }
                      return CalendarFormField(
                        fieldKey: _calendar,
                        calendar: data,
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
                ReminderFormField(
                  fieldKey: _reminder,
                  reminders: _copy.reminders!,
                  editMode: true,
                ),
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
      _copy.calendarId = _calendar.currentState!.value?.source.id;
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
      _copy.attendees = _attendees.currentState?.value;
      _copy.reminders = _reminder.currentState?.value;
      _plugin.saveEvent(_copy);
      Navigator.pop(context);
    }
  }

  Widget _div() {
    return const Divider();
  }
}

typedef MyCallback<T> = void Function(T value);

class CalendarFormField extends StatelessWidget {
  const CalendarFormField({
    Key? key,
    required this.fieldKey,
    required this.calendar,
  }) : super(key: key);
  final Key fieldKey;
  final CalendarItem calendar;

  @override
  Widget build(BuildContext context) {
    return FormField<CalendarItem>(
      key: fieldKey,
      initialValue: calendar,
      validator: (item) => item == null ? 'calendar id is non null' : null,
      builder: (state) {
        final data = state.value!;
        return EditorTile(
          leading: Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: data.color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          content: Text('${data.source.name}'),
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
                        state.didChange(value);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class DateTimeFormField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormField<DateTime>(
      key: fieldKey,
      initialValue: initDate,
      validator: validator,
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
                      onChanged?.call(newDate);
                      state.didChange(newDate);
                    }
                  },
                  child: Text(DateFormat.yMd().format(date)),
                ),
                if (!allday)
                  InkWell(
                    onTap: () async {
                      final ret = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (ret != null) {
                        final newDate = date.add(
                            Duration(hours: ret.hour, minutes: ret.minute));
                        onChanged?.call(newDate);
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

class AttendeeFormField extends StatelessWidget {
  const AttendeeFormField({
    Key? key,
    this.fieldKey,
    required this.attendees,
    this.editMode = false,
  }) : super(key: key);
  final List<Attendee> attendees;
  final bool editMode;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return FormField<List<Attendee>>(
      key: fieldKey,
      initialValue: attendees,
      builder: (state) {
        final attendees = state.value!;
        final children = <Widget>[];

        for (int i = 0; i <= attendees.length; i++) {
          Widget? icon;
          if (i == 0) {
            icon = const Icon(Icons.people_outline);
          }
          if (i == attendees.length) {
            if (editMode) {
              children.add(
                EditorTile(
                  leading: icon,
                  content: const Text("Add"),
                  onTap: () async {
                    try {
                      final contact =
                          await FlutterContactPicker.pickEmailContact();
                      final idx = attendees.indexWhere((element) =>
                          element.emailAddress == contact.email?.email);
                      if (idx == -1) {
                        final value = [...attendees];
                        value.add(
                          Attendee(
                            name: contact.fullName,
                            emailAddress: contact.email?.email,
                            role: AttendeeRole.None,
                          ),
                        );
                        state.didChange(value);
                      }
                    } catch (e) {
                      log('$e');
                    }
                  },
                ),
              );
            }
          } else {
            final attendee = attendees[i];
            children.add(
              EditorTile(
                leading: icon,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${attendee.name}'),
                    Text(
                      '${attendee.emailAddress}',
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ],
                ),
                trailing: !editMode
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          final value = [...attendees];
                          value.removeAt(i);
                          state.didChange(value);
                        },
                      ),
              ),
            );
          }
        }
        return Column(
          children: children,
        );
      },
    );
  }
}

class ReminderFormField extends StatelessWidget {
  const ReminderFormField({
    Key? key,
    this.fieldKey,
    required this.reminders,
    this.editMode = false,
  }) : super(key: key);
  final List<Reminder> reminders;
  final bool editMode;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return FormField<List<Reminder>>(
      key: fieldKey,
      initialValue: reminders,
      builder: (state) {
        final list = state.value!;
        final children = <Widget>[];

        for (int i = 0; i <= list.length; i++) {
          Widget? icon;
          if (i == 0) {
            icon = const Icon(Icons.notifications_outlined);
          }
          if (i == list.length) {
            if (editMode) {
              children.add(
                EditorTile(
                  leading: icon,
                  content: const Text("Add notification"),
                  onTap: () async {
                    final reminder = await _showDialog(context, list);
                    if (reminder != null) {
                      final idx = list.indexWhere(
                          (element) => element.minutes == reminder.minutes);
                      if (idx == -1) {
                        final value = [...list];
                        value.add(reminder);
                        state.didChange(value);
                      }
                    }
                  },
                ),
              );
            }
          } else {
            final reminder = list[i];
            children.add(
              EditorTile(
                leading: icon,
                content: Text('${reminder.minutes} minutes before'),
                trailing: !editMode
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          final value = [...list];
                          value.removeAt(i);
                          state.didChange(value);
                        },
                      ),
              ),
            );
          }
        }
        return Column(
          children: children,
        );
      },
    );
  }

  Future<Reminder?> _showDialog(
      BuildContext context, List<Reminder> reminders) async {
    return await showDialog(
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
                        Navigator.pop(context, Reminder(minutes: e));
                      },
                    ))
                .toList(),
          ),
        );
      },
    ) as Reminder?;
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
