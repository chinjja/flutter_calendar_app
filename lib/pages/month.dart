import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/providers/week_provider.dart';
import 'package:calendar_app/views/week.dart';
import 'package:flutter/material.dart';
import 'package:calendar_app/views/calendar.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:calendar_app/main.dart';

class MonthPage extends StatefulWidget {
  const MonthPage({Key? key}) : super(key: key);

  @override
  _MonthPageState createState() => _MonthPageState();
}

class _MonthPageState extends State<MonthPage> with WidgetsBindingObserver {
  static const dayInMillis = 24 * 60 * 60 * 1000;
  static const _rowHeight = 120.0;
  static final firstDay = DateTime(1970, 1, 1);

  late final _plugin = context.read<CalendarProvider>();
  late final _localizations = MaterialLocalizations.of(context);
  late final firstDayOffset = DateUtils.firstDayOffset(1970, 1, _localizations);

  late final ScrollController _controller = ScrollController(
    initialScrollOffset: getOffsetByWeek(DateTime.now()),
  )..addListener(() async {
      final index = getIndexByOffset(_controller.offset);
      if (_index != index) {
        _index = index;
        _plugin.day.add(getWeekByIndex(index));
      }
    });
  late var _index = getIndexByWeek(DateTime.now());
  final _subs = CompositeSubscription();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    _plugin.day.listen((value) {
      final offset = getOffsetByWeek(value);
      final index = getIndexByOffset(offset);
      if (index != _index) {
        _index = index;
        _scrollToByIndex(index);
      }
    }).addTo(_subs);

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      final result = await _plugin.requestPermissions();
      if (result) {
        _fetchCalendars();
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: const Text('Require Calendar Permission'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                )
              ],
            );
          },
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _subs.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _fetchCalendars();
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final theme = Theme.of(context);
    final yoils = List.generate(
        7, (index) => firstDay.add(Duration(days: index - firstDayOffset)));
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DateTime>(
          stream: _plugin.day,
          builder: (context, snapshot) {
            final date = snapshot.data;
            if (date == null) return const CircularProgressIndicator();
            final startDay = getWeekByIndex(getIndexByWeek(date));
            final title = DateFormat.yMMMM()
                .format(startDay.add(const Duration(days: 3)));
            return Text(title);
          },
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _goto,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              _scrollToByWeek(DateTime.now());
            },
            icon: const Icon(Icons.today),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: theme.primaryColor,
            elevation: 4,
            child: Container(
              padding:
                  EdgeInsets.only(left: padding.left, right: padding.right),
              height: 26,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: yoils
                    .map(
                      (e) => Expanded(
                        child: Text(
                          DateFormat.E().format(e),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.todayTextColor,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _controller,
              itemExtent: _rowHeight,
              itemBuilder: (context, index) {
                final week = getWeekByIndex(index);
                return Provider<WeekProvider>(
                  create: (context) {
                    return WeekProvider(plugin: _plugin, week: week);
                  },
                  dispose: (context, provider) {
                    provider.dispose();
                  },
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: padding.left, right: padding.right),
                    child: WeekWidget(
                      key: ValueKey(week),
                      week: week,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _plugin.newEvent(context);
        },
        child: const Icon(Icons.add),
      ),
      drawer: const Drawer(
        child: CalendarWidget(),
      ),
    );
  }

  void _fetchCalendars() async {
    final result = await _plugin.hasPermissions();
    if (!result) return;
    await _plugin.fetchCalendars();
  }

  void _goto() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: getWeekByIndex(_index),
      firstDate: DateTime(1971),
      lastDate: DateTime(2200),
    );
    if (dt != null) {
      _scrollToByWeek(dt);
    }
  }

  void _scrollToByWeek(DateTime to, [bool animate = true]) {
    final index = getIndexByWeek(to);
    _scrollToByIndex(index, animate);
  }

  void _scrollToByIndex(int index, [bool animate = true]) {
    final offset = getOffsetByIndex(index);
    if (animate && (_index - index).abs() < 10) {
      _controller.animateTo(
        offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    } else {
      _controller.jumpTo(offset);
    }
  }

  int getIndexByWeek(DateTime dt) {
    final days = dt.difference(firstDay).inDays + firstDayOffset;
    return days ~/ 7;
  }

  int getIndexByOffset(double offset) {
    return offset ~/ _rowHeight;
  }

  double getOffsetByWeek(DateTime dt) {
    return getOffsetByIndex(getIndexByWeek(dt));
  }

  double getOffsetByIndex(int index) {
    return index * _rowHeight;
  }

  DateTime getWeekByIndex(int index) {
    return getWeekByOffset(getOffsetByIndex(index));
  }

  DateTime getWeekByOffset(double offset) {
    final index = getIndexByOffset(offset);
    final dt = DateTime.fromMillisecondsSinceEpoch(
      (dayInMillis * index * 7).toInt(),
    );
    return DateUtils.dateOnly(dt.subtract(Duration(days: firstDayOffset)));
  }
}
