import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/constants/storage_keys.dart';
import '../storage/secure_storage_service.dart';
import '../utils/logger.dart';

/// Dedicated HTTP client for the Node.js chat server (port 3000).
/// Reads the chat JWT token from secure storage on every request.
class ChatApiClient {
  static ChatApiClient? _instance;
  static ChatApiClient get instance => _instance ??= ChatApiClient._internal();

  late final Dio _dio;
  final SecureStorageService _secureStorage;

  ChatApiClient._internal({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.chatBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Attach chat JWT token on every request
        final token = await _secureStorage.read(StorageKeys.chatToken);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        AppLogger.info('[ChatApiClient] ${options.method} ${options.path}');
        return handler.next(options);
      },
      onError: (error, handler) {
        AppLogger.error(
            '[ChatApiClient] Error ${error.response?.statusCode}: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  /// POST — used for chat auth login & presigned URLs
  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  /// GET — used for conversations & messages
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  /// PUT — used for uploading binary files to presigned URLs or mock endpoints
  Future<Response> put(String path,
      {dynamic data, Options? options, Map<String, dynamic>? queryParameters}) async {
    return _dio.put(path, data: data, options: options, queryParameters: queryParameters);
  }
}

