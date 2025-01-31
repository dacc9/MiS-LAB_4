import 'package:flutter/material.dart';
import 'package:lab_4/screens//calendar_screen.dart';
import 'package:lab_4/services//notification_service.dart';
import 'package:lab_4/screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(ExamScheduleApp());
}

class ExamScheduleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Распоред на испити',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CalendarScreen(),
    );
  }
}
