import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class M8NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
        'bjo_messages_v2',
        "B'Jo Messages",
        description: 'Notifikasi pesan masuk M8',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('bjo_notification'),
      );

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await android?.requestNotificationsPermission();
    await android?.createNotificationChannel(_chatChannel);
  }

  static Future<void> showChatNotification({
    required String sender,
    required String message,
  }) async {
    const details = AndroidNotificationDetails(
      'bjo_messages_v2',
      "B'Jo Messages",
      channelDescription: 'Notifikasi pesan masuk M8',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('bjo_notification'),
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      'Pesan baru dari $sender',
      message,
      const NotificationDetails(android: details),
    );
  }
}
