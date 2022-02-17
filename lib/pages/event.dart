import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/pages/routes.dart';
import 'package:flutter/material.dart';

class EventPage extends StatelessWidget {
  const EventPage({Key? key, this.item}) : super(key: key);
  final EventItem? item;

  @override
  Widget build(BuildContext context) {
    var item =
        this.item ?? ModalRoute.of(context)!.settings.arguments as EventItem;
    final event = item.source;

    return Scaffold(
      appBar: AppBar(
        actions: item.calendar.isReadOnly
            ? null
            : [
                IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return EventEditorPage(event: item);
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit)),
                PopupMenuButton(
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: () {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(const SnackBar(
                                content: Text('Not implements')));
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
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              color: item.color,
            ),
            Text('Title: ${event.title}'),
            Text('Start: ${event.start}'),
            Text('End: ${event.end}'),
            Text('Allday: ${event.allDay}'),
            Text('Description: ${event.description}'),
            const SizedBox(height: 10),
            Text('${event.toJson()}'),
          ],
        ),
      ),
    );
  }
}
