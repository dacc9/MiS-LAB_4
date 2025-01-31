import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lab_4/services/database_service.dart';
import 'package:lab_4/models/exam_event_model.dart';
import 'package:lab_4/screens/map_screen.dart';
import 'package:lab_4/screens/add_event_screen.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DatabaseService _databaseService;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<ExamEvent> _selectedEvents = [];
  Map<DateTime, List<ExamEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _loadAllEvents();
    _loadEvents(_selectedDay);
  }

  Future<void> _loadAllEvents() async {
    final allEvents = await _databaseService.getEvents();
    setState(() {
      _events = {};
      for (var event in allEvents) {
        final date = DateTime(
          event.dateTime.year,
          event.dateTime.month,
          event.dateTime.day,
        );
        _events[date] = [...(_events[date] ?? []), event];
      }
    });
  }

  void _loadEvents(DateTime day) async {
    final events = await _databaseService.getEventsForDay(day);
    setState(() {
      _selectedEvents = events;
    });
  }

  Future<void> _deleteEvent(ExamEvent event) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Избриши испит'),
          content: Text('Дали сте сигурни дека сакате да го избришете испитот ${event.title}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Откажи'),
            ),
            TextButton(
              onPressed: () async {
                await _databaseService.deleteEvent(event.id!);
                Navigator.pop(context);
                _loadAllEvents();  // Reload all events to update calendar markers
                _loadEvents(_selectedDay);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Испитот е успешно избришан')),
                );
              },
              child: Text('Избриши'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  List<ExamEvent> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Распоред на испити'),
        actions: [
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _loadEvents(selectedDay);
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              markerSize: 8,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final events = _getEventsForDay(day);
                if (events.isNotEmpty) {
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                final event = _selectedEvents[index];
                return Dismissible(
                  key: Key(event.id.toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 16.0),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteEvent(event);
                  },
                  child: ListTile(
                    title: Text(event.title),
                    subtitle: Text('${event.location} - ${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapScreen(selectedEvent: event),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteEvent(event),
                      color: Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEventScreen()),
          );
          if (result == true) {
            _loadAllEvents();  // Reload all events to update calendar markers
            _loadEvents(_selectedDay);
          }
        },
      ),
    );
  }
}