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

    Widget dateText;
    if (event.allDay ?? false) {
      if (event.start!.isAtSameMomentAs(event.end!)) {
        dateText = Text(DateFormat.yMd().format(event.start!));
      } else {
        final s = DateFormat.yMd().format(event.start!);
        final e = DateFormat.yMd().format(event.end!);
        dateText = Text('$s ~ $e');
      }
    } else {
      dateText = Text(DateFormat.yMd().add_j().format(event.start!));
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
                        dateText,
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
              AttendeeWidget(attendees: event.attendees ?? [], onChanged: null),
              ReminderWidget(reminders: event.reminders ?? [], onChanged: null),
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
