import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/providers/week_provider.dart';
import 'package:calendar_app/views/week.dart';
import 'package:flutter/material.dart';
import 'package:calendar_app/views/calendar.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

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

  late final _title = BehaviorSubject.seeded(getIndexByWeek(DateTime.now()));

  ScrollController? _controller;
  late var _index = getIndexByWeek(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _controller = ScrollController(
        initialScrollOffset: getOffsetByWeek(DateTime.now()),
      );
      _controller!.addListener(() async {
        final index = getIndexByOffset(_controller!.offset);
        if (_index != index) {
          _index = index;
          _title.add(index);
        }
      });
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _controller?.dispose();
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
    final theme = Theme.of(context);
    final yoils = List.generate(
        7, (index) => firstDay.add(Duration(days: index - firstDayOffset)));
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<int>(
          stream: _title,
          builder: (context, snapshot) {
            final index = snapshot.data;
            if (index == null) return const CircularProgressIndicator();
            final startDay = getWeekByIndex(index);
            final title = DateFormat.yMMMM()
                .format(startDay.add(const Duration(days: 3)));
            return Text(title);
          },
        ),
        elevation: 0,
        actions: [
          const IconButton(
            onPressed: null,
            icon: Icon(Icons.search),
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
            child: SizedBox(
              height: 26,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: yoils
                    .map(
                      (e) => Expanded(
                        child: Text(
                          DateFormat.E().format(e),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
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
                    final wp = WeekProvider(plugin: _plugin, week: week);
                    wp.fetchEvents();
                    return wp;
                  },
                  dispose: (context, provider) {
                    provider.dispose();
                  },
                  child: WeekWidget(
                    key: ValueKey(week),
                    week: week,
                    callback: (day) {
                      if (day != null) {
                        final offset = getOffsetByWeek(day);
                        final height =
                            context.findRenderObject()!.semanticBounds.height;
                        final curr = _controller?.offset ?? 0;
                        if (offset < curr ||
                            offset >
                                curr +
                                    _rowHeight * (height ~/ _rowHeight - 1)) {
                          _scrollToByWeek(day);
                        } else {
                          final n = height ~/ _rowHeight - 2;
                          final h = _rowHeight * n;
                          if (offset > curr + h) {
                            _scrollToByIndex(getIndexByWeek(day) - n);
                          }
                        }
                      }
                      _fetchCalendars();
                    },
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
      _controller?.animateTo(
        offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
      );
    } else {
      _controller?.jumpTo(offset);
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
