import 'package:calendar_app/model/model.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CalendarWidget extends StatelessWidget {
  const CalendarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CalendarProvider>();
    return SafeArea(
      child: StreamBuilder<Map<String, List<CalendarItem>>>(
        stream: provider.calendars.map((data) {
          final map = <String, List<CalendarItem>>{};
          for (final item in data) {
            map.putIfAbsent(item.source.accountName!, () => []).add(item);
          }
          return map;
        }),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: data.entries.map((e) {
                return Column(
                  children: [
                    ListTile(
                      title: Text(e.key),
                    ),
                    ...e.value.map((e) => _item(provider, e)),
                    const Divider(),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _item(CalendarProvider cp, CalendarItem item) {
    return CheckboxListTile(
      title: Text(item.source.name ?? '<--->'),
      activeColor: Color(item.source.color ?? 0),
      value: item.isSelected,
      onChanged: (value) {
        item.isSelected = !item.isSelected;
        cp.updateCalendar([item]);
      },
    );
  }
}
