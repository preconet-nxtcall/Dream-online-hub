import 'package:dio/dio.dart';
import '../../utils/logger.dart';

class LoggingInterceptor extends Interceptor {
  final bool logResponseBody;
  final bool logRequestHeader;

  LoggingInterceptor({
    this.logResponseBody = true,
    this.logRequestHeader = true,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['requestStartTime'] = DateTime.now().millisecondsSinceEpoch;

    AppLogger.info('--> ${options.method.toUpperCase()} ${options.uri}');
    if (logRequestHeader && options.headers.isNotEmpty) {
      AppLogger.info('Headers: ${options.headers}');
    }
    if (options.queryParameters.isNotEmpty) {
      AppLogger.info('QueryParameters: ${options.queryParameters}');
    }
    if (options.data != null) {
      AppLogger.info('RequestBody: ${options.data}');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra['requestStartTime'] as int?;
    final duration = startTime != null
        ? '${DateTime.now().millisecondsSinceEpoch - startTime}ms'
        : 'N/A';

    AppLogger.info('<-- ${response.statusCode} ${response.requestOptions.uri} ($duration)');
    if (logResponseBody && response.data != null) {
      AppLogger.info('ResponseBody: ${response.data}');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = err.requestOptions.extra['requestStartTime'] as int?;
    final duration = startTime != null
        ? '${DateTime.now().millisecondsSinceEpoch - startTime}ms'
        : 'N/A';

    AppLogger.error(
      '<-- ERROR [${err.response?.statusCode ?? 'NO_RESPONSE'}] ${err.requestOptions.uri} ($duration)',
      err,
      err.stackTrace,
    );

    if (err.response?.data != null) {
      AppLogger.error('ErrorResponseBody: ${err.response?.data}');
    }

    handler.next(err);
  }
}
