import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:lab_4/models/exam_event_model.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tapped logic here
      },
    );
  }

  Future<bool> scheduleNotification(ExamEvent event) async {
    try {
      final scheduledTime = event.dateTime.subtract(const Duration(hours: 1));

      if (scheduledTime.isAfter(DateTime.now())) {
        final location = tz.local;
        final scheduledDate = tz.TZDateTime.from(scheduledTime, location);

        await _notifications.zonedSchedule(
          event.id ?? 0,
          'Потсетник за испит',
          '${event.title} започнува за 1 час',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'exam_reminders',
              'Потсетници за испити',
              channelDescription: 'Нотификации за претстојни испити',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error scheduling notification: $e');
      return false;
    }
  }
}