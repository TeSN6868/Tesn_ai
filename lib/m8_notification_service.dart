import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class M8NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
    'm8_chat_v2',
    'M8 Chat',
    description: 'Notifikasi pesan masuk M8',
    importance: Importance.high,
    playSound: true,
  );

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);

    final android =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
    await android?.createNotificationChannel(_chatChannel);
  }

  static Future<void> showChatNotification({
    required String sender,
    required String message,
  }) async {
    const details = AndroidNotificationDetails(
      'm8_chat_v2',
      'M8 Chat',
      channelDescription: 'Notifikasi pesan masuk M8',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('m8_notification'),
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Pesan baru dari $sender',
      message,
      const NotificationDetails(android: details),
    );
  }
}
