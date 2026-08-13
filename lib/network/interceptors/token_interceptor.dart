import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/storage_keys.dart';
import '../../storage/secure_storage_service.dart';
import '../../utils/logger.dart';

class TokenInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final Function()? _onSessionExpired;
  final Dio _refreshTokenDio;

  bool _isRefreshing = false;
  final List<_RequestQueueItem> _failedRequestsQueue = [];

  TokenInterceptor({
    SecureStorageService? secureStorage,
    Function()? onSessionExpired,
    Dio? refreshTokenDio,
  })  : _secureStorage = secureStorage ?? SecureStorageService(),
        _onSessionExpired = onSessionExpired,
        _refreshTokenDio = refreshTokenDio ?? Dio();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final bool skipAuth = options.headers['no-auth'] == true;
    if (!skipAuth) {
      final token = await _secureStorage.read(StorageKeys.authToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    options.headers.remove('no-auth');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    // Check if error is 401 Unauthorized and not calling auth endpoints
    final isAuthEndpoint = requestOptions.path.contains(ApiEndpoints.login) ||
        requestOptions.path.contains(ApiEndpoints.refreshToken);

    if (response?.statusCode == 401 && !isAuthEndpoint) {
      if (!_isRefreshing) {
        _isRefreshing = true;

        try {
          final refreshToken = await _secureStorage.read(StorageKeys.refreshToken);
          if (refreshToken == null || refreshToken.isEmpty) {
            _handleSessionExpiry(handler, err);
            return;
          }

          AppLogger.info('Attempting silent token refresh...');

          final String baseUrl = requestOptions.baseUrl.endsWith('/')
              ? requestOptions.baseUrl.substring(0, requestOptions.baseUrl.length - 1)
              : requestOptions.baseUrl;
          final String refreshEndpoint = ApiEndpoints.refreshToken.startsWith('/')
              ? ApiEndpoints.refreshToken
              : '/${ApiEndpoints.refreshToken}';
          final String refreshUrl = '$baseUrl$refreshEndpoint';

          final refreshResponse = await _refreshTokenDio.post(
            refreshUrl,
            data: {'action': 'refresh_token', 'refresh_token': refreshToken},
            options: Options(headers: {'Content-Type': 'application/json'}),
          );

          if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
            final data = refreshResponse.data;
            final newAccessToken = (data['access_token'] ?? data['token'] ?? data['data']?['access_token'] ?? '').toString();
            final newRefreshToken = (data['refresh_token'] ?? data['data']?['refresh_token'])?.toString();

            if (newAccessToken.isNotEmpty) {
              await _secureStorage.write(StorageKeys.authToken, newAccessToken);
              if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                await _secureStorage.write(StorageKeys.refreshToken, newRefreshToken);
              }

              AppLogger.info('Token refresh successful!');
              _isRefreshing = false;

              // Retry original request
              requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retriedResponse = await _refreshTokenDio.fetch(requestOptions);
              handler.resolve(retriedResponse);

              // Process queued requests
              _processQueue(newAccessToken);
              return;
            }
          }

          _handleSessionExpiry(handler, err);
        } catch (refreshErr) {
          AppLogger.error('Failed to refresh token: $refreshErr');
          _handleSessionExpiry(handler, err);
        } finally {
          _isRefreshing = false;
        }
      } else {
        // Enqueue request while refresh is in progress
        _failedRequestsQueue.add(_RequestQueueItem(
          options: requestOptions,
          handler: handler,
        ));
      }
    } else {
      handler.next(err);
    }
  }

  void _processQueue(String newAccessToken) async {
    for (final item in _failedRequestsQueue) {
      try {
        item.options.headers['Authorization'] = 'Bearer $newAccessToken';
        final response = await _refreshTokenDio.fetch(item.options);
        item.handler.resolve(response);
      } catch (e) {
        if (e is DioException) {
          item.handler.reject(e);
        } else {
          item.handler.reject(DioException(requestOptions: item.options, error: e));
        }
      }
    }
    _failedRequestsQueue.clear();
  }

  void _handleSessionExpiry(ErrorInterceptorHandler handler, DioException err) async {
    _isRefreshing = false;
    for (final item in _failedRequestsQueue) {
      item.handler.reject(err);
    }
    _failedRequestsQueue.clear();

    await _secureStorage.deleteAll();
    AppLogger.warning('Session expired. User logged out.');
    if (_onSessionExpired != null) {
      _onSessionExpired!();
    }
    handler.next(err);
  }
}

class _RequestQueueItem {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _RequestQueueItem({required this.options, required this.handler});
}
