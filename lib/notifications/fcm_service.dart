import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../storage/local_storage_repository.dart';
import '../utils/logger.dart';
import 'fcm_deep_link_router.dart';
import 'notification_service.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  AppLogger.info('Handling background FCM message [${message.messageId}]: ${message.notification?.title}');
}

class FCMService {
  static FCMService? _instance;
  static FCMService get instance => _instance ??= FCMService._internal();

  FirebaseMessaging? _firebaseMessaging;
  final NotificationService _notificationService;
  final LocalStorageRepository _localStorage;

  String? _fcmToken;
  Function(FCMDeepLinkTarget target)? _onDeepLinkCallback;

  FCMService._internal({
    FirebaseMessaging? firebaseMessaging,
    NotificationService? notificationService,
    LocalStorageRepository? localStorage,
  })  : _firebaseMessaging = firebaseMessaging,
        _notificationService = notificationService ?? NotificationService.instance,
        _localStorage = localStorage ?? LocalStorageRepositoryImpl();

  factory FCMService({
    FirebaseMessaging? firebaseMessaging,
    NotificationService? notificationService,
    LocalStorageRepository? localStorage,
  }) {
    return FCMService._internal(
      firebaseMessaging: firebaseMessaging,
      notificationService: notificationService,
      localStorage: localStorage,
    );
  }

  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging, permissions, handlers, and deep linking
  Future<void> init({Function(FCMDeepLinkTarget target)? onDeepLink}) async {
    _onDeepLinkCallback = onDeepLink;

    try {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        AppLogger.warning('Firebase.initializeApp warning: $e');
      }

      _firebaseMessaging ??= FirebaseMessaging.instance;

      await _requestPermissions();
      await _notificationService.init(onNotificationClick: (payload) {
        final target = FCMDeepLinkRouter.parsePayload(payload);
        if (target != null && _onDeepLinkCallback != null) {
          _onDeepLinkCallback!(target);
        }
      });

      // Background Message Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Foreground Message Handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background App Opened Click Listener
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      // Killed State Initial Message Handler
      final initialMessage = await _firebaseMessaging?.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info('App launched from killed state via FCM notification!');
        _handleNotificationClick(initialMessage);
      }

      // Fetch & Monitor FCM Token
      await _syncFCMToken();

      AppLogger.info('FCMService initialized successfully!');
    } catch (e) {
      AppLogger.error('Error initializing FCMService: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (_firebaseMessaging == null) return;
    final settings = await _firebaseMessaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    AppLogger.info('FCM User Permission Status: ${settings.authorizationStatus}');
  }

  Future<void> _syncFCMToken() async {
    try {
      if (_firebaseMessaging == null) return;
      _fcmToken = await _firebaseMessaging!.getToken();
      if (_fcmToken != null) {
        AppLogger.info('FCM Token generated: $_fcmToken');
      }
      _firebaseMessaging!.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        AppLogger.info('FCM Token refreshed: $newToken');
      });
    } catch (e) {
      AppLogger.warning('FCM getToken non-fatal exception: $e');
    }
  }

  /// Foreground Notification Message Processor
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('Received Foreground FCM Message: ${message.notification?.title}');

    final notification = message.notification;
    final data = message.data;

    final String title = notification?.title ?? data['title'] ?? 'New Message';
    final String body = notification?.body ?? data['body'] ?? 'You received a new notification';

    // Increment Unread Badge in Local Storage
    final userId = (data['user_id'] ?? data['sender_id'] ?? '').toString();
    if (userId.isNotEmpty) {
      _localStorage.incrementUnread(userId);
    }

    // Display Heads-Up Local Notification Banner
    _notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: data.isNotEmpty ? data.toString() : null,
    );
  }

  /// Notification Click Processor (Background & Killed State)
  void _handleNotificationClick(RemoteMessage message) {
    AppLogger.info('Notification Clicked! Payload data: ${message.data}');
    final target = FCMDeepLinkRouter.parsePayload(message.data);
    if (target != null && _onDeepLinkCallback != null) {
      _onDeepLinkCallback!(target);
    }
  }
}
