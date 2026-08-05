import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/logger.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important real-time chat and agency push notifications.',
    importance: Importance.max,
    playSound: true,
  );

  NotificationService._internal();

  factory NotificationService({FlutterLocalNotificationsPlugin? localNotifications}) {
    if (localNotifications != null) {
      final service = NotificationService._internal();
      return service;
    }
    return instance;
  }

  /// Initialize Local Notification Plugin & Android/iOS Channels
  Future<void> init({Function(String? payload)? onNotificationClick}) async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          AppLogger.info('Foreground Local Notification clicked with payload: ${response.payload}');
          if (onNotificationClick != null) {
            onNotificationClick(response.payload);
          }
        },
      );

      // Create High Importance Channel on Android
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_channel);
      }

      AppLogger.info('NotificationService initialized successfully!');
    } catch (e) {
      AppLogger.error('NotificationService init error: $e');
    }
  }

  /// Show Heads-Up Foreground Local Notification Banner
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important real-time chat and agency push notifications.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }
}
