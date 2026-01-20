import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zimax/src/pages/extrapage.dart/callpage.dart';

class NotificationService {
  /// Global navigator key to push pages from anywhere
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Local notifications plugin
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification service
  static Future<void> init() async {
    /// 1️⃣ Initialize local notifications
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    /// 2️⃣ Request permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    /// 3️⃣ Save initial FCM token
    await _saveFcmToken();

    /// 4️⃣ Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _saveFcmToken(token: token);
    });

    /// 5️⃣ Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    /// 6️⃣ Handle taps (background / terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleTap(initialMessage);
    }
  }

  /// Save FCM token to Supabase safely
  static Future<void> _saveFcmToken({String? token}) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    token ??= await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await supabase.from('device_tokens').upsert(
      {
        'user_id': user.id,
        'token': token,
      },
      onConflict: 'token',
    );

    print('✅ FCM token saved for user: ${user.id}');
  }

  /// Handle foreground notifications
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _notifications.show(
      0,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general_channel',
          'General Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Handle taps on notifications
  static void _handleTap(RemoteMessage message) {
    final data = message.data;

    if (data['type'] == 'call') {
      final callId = data['call_id'] ?? '';
      final isVideo = data['is_video'] == 'true';
      final userId = data['receiver_id'] ?? '';
      final friendName = data['caller_name'] ?? 'Unknown';

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => CallPage(
            callId: callId,
            isCaller: false,
            isVideo: isVideo,
            userId: userId,
            friendName: friendName,
          ),
        ),
      );
    }
  }
}
