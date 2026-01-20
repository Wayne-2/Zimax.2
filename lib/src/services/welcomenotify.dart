import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> showWelcomeNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'welcome_channel',
      'Welcome Notifications',
      channelDescription: 'Welcome messages',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('welcome'),
      playSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        sound: 'welcome.caf', // optional for iOS
      ),
    );

    await _notifications.show(
      100,
      'Welcome to Zimax 🎉',
      'We’re glad to have you here!',
      notificationDetails,
    );
  }
}
