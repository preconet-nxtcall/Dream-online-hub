import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/network_exceptions.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/php_sanitizer_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/token_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({
    Dio? dio,
    String? baseUrl,
    Function()? onSessionExpired,
    bool enableLogging = true,
    bool enableRetry = true,
  }) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
            connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
            receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
            sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
            responseType: ResponseType.plain,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    // 0. PHP Sanitizer Interceptor (Strips HTML/PHP warnings before JSON decoding)
    _dio.interceptors.add(PhpSanitizerInterceptor());

    // 1. Token Interceptor (Header Injection & 401 Silent Refresh)
    _dio.interceptors.add(TokenInterceptor(
      onSessionExpired: onSessionExpired,
    ));

    // 2. Retry Interceptor (Exponential Backoff)
    if (enableRetry) {
      _dio.interceptors.add(RetryInterceptor(dio: _dio));
    }

    // 3. Logging Interceptor
    if (enableLogging) {
      _dio.interceptors.add(LoggingInterceptor());
    }
  }

  /// Exposed Dio instance for custom request configurations
  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on NetworkException {
      rethrow;
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException(message: 'Unexpected network error: ${e.toString()}');
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on NetworkException {
      rethrow;
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException(message: 'Unexpected network error: ${e.toString()}');
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on NetworkException {
      rethrow;
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException(message: 'Unexpected network error: ${e.toString()}');
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on NetworkException {
      rethrow;
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException(message: 'Unexpected network error: ${e.toString()}');
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on NetworkException {
      rethrow;
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException(message: 'Unexpected network error: ${e.toString()}');
    }
  }

  Future<Response<T>> uploadFile<T>(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: (options ?? Options()).copyWith(
          contentType: 'multipart/form-data',
        ),
        cancelToken: cancelToken,
      );
    } on NetworkException {
      rethrow;
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    } catch (e) {
      throw NetworkException(message: 'Unexpected network error: ${e.toString()}');
    }
  }
}
