import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  static void debug(String message) {
    if (!kReleaseMode) _logger.d(message);
  }

  static void info(String message) {
    if (!kReleaseMode) _logger.i(message);
  }

  static void warning(String message) {
    if (!kReleaseMode) _logger.w(message);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error is StackTrace && stackTrace == null) {
      _logger.e(message, error: null, stackTrace: error);
    } else {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }
}
