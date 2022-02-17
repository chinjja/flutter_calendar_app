import 'package:calendar_app/model/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventEditorPage extends StatefulWidget {
  const EventEditorPage({Key? key, this.date, this.event}) : super(key: key);
  final DateTime? date;
  final EventItem? event;

  @override
  _EventEditorPageState createState() => _EventEditorPageState();
}

class _EventEditorPageState extends State<EventEditorPage> {
  late final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event?.source;
    _title.text = event?.title ?? '';
    final allday = event?.allDay ?? false;
    final now = widget.date ?? DateTime.now();
    final def = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      (now.minute + 7.5) ~/ 15 * 15,
    );
    final start = event?.start ?? def;
    final end = event?.end ?? start.add(const Duration(hours: 1));

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('Not implements')));
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _row(
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
            _row(
              leading: const Icon(Icons.schedule_outlined),
              child: _text('All day'),
              tailing: Switch(
                value: allday,
                onChanged: (v) {
                  setState(() {
                    event?.allDay = v;
                  });
                },
              ),
            ),
            _row(
              child: _date(context, start),
              tailing: allday ? null : _time(context, start),
            ),
            _row(
              child: _date(context, end),
              tailing: allday ? null : _time(context, end),
            ),
            _row(
              leading: const Icon(Icons.language_outlined),
              child: _text('한국 표준시'),
            ),
            _row(
              leading: const Icon(Icons.refresh_outlined),
              child: _text('${event?.recurrenceRule ?? '반복안함'}'),
            ),
            _div(),
            _row(
              leading: const Icon(Icons.people_outline),
              child: _input('Attendees'),
            ),
            _row(
              child: _input('Add...'),
            ),
            _div(),
            _row(
              leading: const Icon(Icons.location_on_outlined),
              child: _input('Location'),
            ),
            _div(),
            _row(
              leading: const Icon(Icons.notifications_outlined),
              child: _input('Notifications'),
            ),
            _row(
              child: _input('Add...'),
            ),
            _div(),
            _row(
              leading: const Icon(Icons.description_outlined),
              child: _input('Description'),
            ),
            _div(),
            _row(
              leading: const Icon(Icons.attach_file),
              child: _input('Attach file'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _div() {
    return const Divider(color: Colors.black);
  }

  Widget _row({required Widget child, Widget? leading, Widget? tailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: leading,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(child: child),
          if (tailing != null) tailing,
        ],
      ),
    );
  }

  Widget _date(BuildContext context, DateTime date) {
    return GestureDetector(
      onTap: () {
        showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000, 1, 1),
          lastDate: DateTime(2100, 1, 1),
        );
      },
      child: Text(
        DateFormat.yMEd().format(date),
        style: _textStyle(),
      ),
    );
  }

  Widget _time(BuildContext context, DateTime date) {
    return GestureDetector(
      onTap: () {
        showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(date),
        );
      },
      child: Text(
        DateFormat.jm().format(date),
        style: _textStyle(),
      ),
    );
  }

  TextStyle _textStyle() {
    return const TextStyle(fontSize: 18);
  }

  Widget _text(String text) {
    return Text(
      text,
      style: _textStyle(),
    );
  }

  Widget _input(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        border: InputBorder.none,
      ),
      style: _textStyle(),
    );
  }
}
