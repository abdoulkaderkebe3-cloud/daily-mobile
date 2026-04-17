import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialiser() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
    );
  }

  static Future<void> programmerRappelQuotidien({bool demain = false}) async {
    // Programmer un rappel à 18:00
    await _notificationsPlugin.zonedSchedule(
      0,
      'N\'oublie pas ton défi !',
      'Tu n\'as pas encore joué à The Daily Muse aujourd\'hui. Viens relever l\'énigme !',
      _prochaineInstanceDe18h(demain: demain),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rappel_quotidien',
          'Rappels quotidiens',
          channelDescription: 'Notifications pour rappeler de jouer au défi du jour',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> annulerRappel() async {
    await _notificationsPlugin.cancel(0);
  }

  static tz.TZDateTime _prochaineInstanceDe18h({bool demain = false}) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 18);
    
    if (demain || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
