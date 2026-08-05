import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/agency_app.dart';
import 'app/user_app.dart';
import 'notifications/fcm_service.dart';
import 'storage/local_storage_repository.dart';
import 'storage/local_storage_service.dart';
import 'utils/logger.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Intercept framework & platform level unhandled errors to prevent native OS process crash
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      AppLogger.error('Flutter Framework Error: ${details.exception}', details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error('Unhandled Asynchronous Error: $error', error, stack);
      return true; // Prevents "App keeps stopping" popup on Android
    };

    // Initialize Hive Storage
    try {
      await HiveLocalStorageService().init();
    } catch (e, stack) {
      AppLogger.error('Hive initialization error: $e', stack);
    }

    // Initialize Firebase Cloud Messaging asynchronously
    try {
      await FCMService.instance.init();
    } catch (e, stack) {
      AppLogger.error('FCM initialization error: $e', stack);
    }

    // Determine user role preference (Agency vs User App)
    bool isUserApp = false;
    try {
      final storedUser = LocalStorageRepositoryImpl().getUser();
      isUserApp = storedUser?.isUser ?? false;
    } catch (e) {
      AppLogger.warning('User storage check exception: $e');
    }

    if (isUserApp) {
      runApp(const UserApp());
    } else {
      runApp(const AgencyApp());
    }
  }, (error, stack) {
    AppLogger.error('Uncaught Zoned Error: $error', stack);
  });
}
