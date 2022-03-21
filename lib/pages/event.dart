import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/pages/routes.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventPage extends StatelessWidget {
  const EventPage({Key? key, required this.item}) : super(key: key);
  final EventItem item;

  @override
  Widget build(BuildContext context) {
    final event = item.source;
    final calendar = item.calendar.source;
    final plugin = Provider.of<CalendarProvider>(context, listen: false);

    String dateText;
    if (event.allDay ?? false) {
      final format = DateFormat.yMd().format;
      dateText = format(event.start!);
      if (!DateUtils.isSameDay(event.start, event.end)) {
        dateText += '~${format(event.end!)}';
      }
    } else {
      if (DateUtils.isSameDay(event.start, event.end)) {
        final format = DateFormat.jm().format;
        dateText =
            '${DateFormat.yMd().format(event.start!)} ${format(event.start!)}~${format(event.end!)}';
      } else {
        final format = DateFormat.yMd().add_jm().format;
        dateText = '${format(event.start!)}~${format(event.end!)}';
      }
    }
    return Scaffold(
      appBar: AppBar(
        actions: item.calendar.isReadOnly
            ? null
            : [
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Provider.of<CalendarProvider>(context, listen: false)
                          .editEvent(context, item);
                    },
                    icon: const Icon(Icons.edit)),
                PopupMenuButton(
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: () {
                          plugin.deleteEvent(item.source);
                          Navigator.pop(context);
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('Copy'),
                        onTap: () {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(const SnackBar(
                                content: Text('Not implements')));
                        },
                      ),
                    ];
                  },
                ),
              ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 60,
                child: EditorTile(
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
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          event.title ?? '(제목 없음)',
                          maxLines: null,
                          style: const TextStyle(fontSize: 20),
                        ),
                        Text(dateText),
                      ],
                    )),
              ),
              EditorTile(
                leading: const Icon(Icons.calendar_today_outlined),
                content: Text('${calendar.name}'),
              ),
              EditorTile(
                leading: const Icon(Icons.lock_outline),
                content: Text(event.availability.name),
              ),
              AttendeeFormField(
                attendees: event.attendees?.map((e) => e!).toList() ?? [],
              ),
              ReminderFormField(reminders: event.reminders ?? []),
              if (event.description != null && event.description!.isNotEmpty)
                EditorTile(
                  leading: const Icon(Icons.description_outlined),
                  content: Text(
                    event.description!,
                    maxLines: null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
