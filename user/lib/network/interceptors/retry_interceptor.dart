import 'dart:async';
import 'package:dio/dio.dart';
import '../../utils/logger.dart';

class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final int initialDelayMs;
  final Dio _dio;

  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 3,
    this.initialDelayMs = 1000,
  }) : _dio = dio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final int retryCount = extra['retryCount'] ?? 0;

    if (_shouldRetry(err) && retryCount < maxRetries) {
      final int nextRetryCount = retryCount + 1;
      final int delayMs = initialDelayMs * (1 << (nextRetryCount - 1)); // Exponential backoff: 1s, 2s, 4s

      AppLogger.warning(
        'Retrying request [${err.requestOptions.method} ${err.requestOptions.path}] (Attempt $nextRetryCount of $maxRetries) in ${delayMs}ms...',
      );

      await Future.delayed(Duration(milliseconds: delayMs));

      try {
        err.requestOptions.extra['retryCount'] = nextRetryCount;
        final response = await _dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        if (e is DioException) {
          return super.onError(e, handler);
        }
      }
    }

    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response != null && err.response!.statusCode == 503);
  }
}
