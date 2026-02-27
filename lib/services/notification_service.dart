import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Addis_Ababa'));
    } catch (_) {
      // Fallback if specific location is not found
      tz.setLocalLocation(tz.UTC);
    }

    await _scheduleDaily();
  }

  Future<void> _scheduleDaily() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_word_channel',
        'Daily Word',
        channelDescription: 'Daily Amharic word reminder',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    final now = tz.TZDateTime.now(tz.local);
    // Schedule for exactly 12:00 AM (midnight)
    var time = tz.TZDateTime(tz.local, now.year, now.month, now.day, 0, 0, 0);

    if (time.isBefore(now)) {
      time = time.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      0,
      'አዲስ የቀኑ ቃል',
      'ዛሬውን አዲስ ቃል አሁኑኑ ይመልከቱ!',
      time,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'general_channel',
        'General Notifications',
        channelDescription: 'Important app updates',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await _plugin.show(id, title, body, details);
  }

  Future<void> scheduleSubscriptionEndNotification(Duration duration) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'subscription_channel',
        'Subscription Alerts',
        channelDescription: 'Notifications about your subscription status',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    final scheduledDate = tz.TZDateTime.now(tz.local).add(duration);

    await _plugin.zonedSchedule(
      1,
      'Subscription Ending Soon',
      'Your ad-free subscription is about to end. Renew now to stay premium!',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
