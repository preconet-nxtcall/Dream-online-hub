import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/agency_app.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart' as di;
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

    // Initialize Dependency Injection for Agency
    await di.init(AppFlavor.agency);

    runApp(const AgencyApp());
  }, (error, stack) {
    AppLogger.error('Uncaught Zoned Error: $error', stack);
  });
}
