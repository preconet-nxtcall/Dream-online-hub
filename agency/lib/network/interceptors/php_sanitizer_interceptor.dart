import 'dart:convert';
import 'package:dio/dio.dart';
import '../../utils/logger.dart';

/// Interceptor that strips PHP HTML warnings, notices, and extraneous output
/// preceding valid JSON responses before decoding.
class PhpSanitizerInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is String) {
      final sanitized = _parseCleanJson(response.data as String);
      if (sanitized != null) {
        response.data = sanitized;
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.data is String) {
      final sanitized = _parseCleanJson(err.response!.data as String);
      if (sanitized != null) {
        err.response!.data = sanitized;
      }
    }
    handler.next(err);
  }

  dynamic _parseCleanJson(String rawData) {
    final str = rawData.trim();
    if (str.isEmpty) return null;

    final firstBrace = str.indexOf('{');
    final firstBracket = str.indexOf('[');

    int start = -1;
    if (firstBrace != -1 && firstBracket != -1) {
      start = firstBrace < firstBracket ? firstBrace : firstBracket;
    } else if (firstBrace != -1) {
      start = firstBrace;
    } else if (firstBracket != -1) {
      start = firstBracket;
    }

    if (start >= 0) {
      final cleanJsonStr = str.substring(start);
      try {
        return jsonDecode(cleanJsonStr);
      } catch (e) {
        AppLogger.warning('PhpSanitizerInterceptor: Failed to parse sanitized JSON: $e');
      }
    }

    try {
      return jsonDecode(str);
    } catch (_) {
      return null;
    }
  }
}
