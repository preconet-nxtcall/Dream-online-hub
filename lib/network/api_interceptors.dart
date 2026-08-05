import 'package:dio/dio.dart';
import '../core/constants/storage_keys.dart';
import '../storage/secure_storage_service.dart';
import '../utils/logger.dart';

class ApiInterceptors extends Interceptor {
  final SecureStorageService _secureStorage;
  final Function()? _onSessionExpired;

  ApiInterceptors({
    SecureStorageService? secureStorage,
    Function()? onSessionExpired,
  })  : _secureStorage = secureStorage ?? SecureStorageService(),
        _onSessionExpired = onSessionExpired;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.read(StorageKeys.authToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    AppLogger.info('API Request [${options.method}] => PATH: ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.info('API Response [${response.statusCode}] => PATH: ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error('API Error [${err.response?.statusCode}] => PATH: ${err.requestOptions.path}', err, err.stackTrace);
    
    // 401 Unauthorized -> Handle Session Expiry
    if (err.response?.statusCode == 401) {
      AppLogger.warning('Session expired (401 Unauthorized). Triggering logout flow...');
      if (_onSessionExpired != null) {
        _onSessionExpired!();
      }
    }

    handler.next(err);
  }
}
