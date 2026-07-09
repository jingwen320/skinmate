import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _notificationsPlugin.initialize(
      const  InitializationSettings(android: initializationSettingsAndroid),

      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("🎯 Notification clicked: ${response.payload}");
      },
    );

    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();

    // 🚀 NEW CHANNEL ID (v11) to force a total reset
    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'skincare_v11', 
        'Skincare Reminders',
        description: 'Daily reminders for your routine',
        importance: Importance.max,
      ),
    );

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'order_updates', 
        'Order Updates',
        description: 'Real-time updates regarding your store purchases',
        importance: Importance.max,
        playSound: true,
      ),
    );

    await androidImplementation?.requestNotificationsPermission();
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'order_updates',      // Must match the new channel ID above
          'Order Updates',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          playSound: true,
        ),
      ),
    );
  }

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // 🚀 FORCE Malaysia Location
    final penang = tz.getLocation('Asia/Kuala_Lumpur');

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'skincare_v11',
          'Skincare Reminders',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          channelShowBadge: true,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    // 🚀 THE FIX: Use explicit Malaysia location
    final penang = tz.getLocation('Asia/Kuala_Lumpur');
    final now = tz.TZDateTime.now(penang);
    
    // 🔍 This MUST show 22:40... NOT 14:40Z
    print("🔔 [DEBUG] ACTUAL PENANG TIME: $now"); 

    tz.TZDateTime scheduledDate =
        tz.TZDateTime(penang, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    print("⏰ [DEBUG] NOTIFICATION TARGET: $scheduledDate");
    return scheduledDate;
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> requestExactAlarmPermission() async {
    if (await Permission.scheduleExactAlarm.isDenied) {
      await openAppSettings(); 
    }
  }
}