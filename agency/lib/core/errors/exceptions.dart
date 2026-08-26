export 'network_exceptions.dart';

class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({required this.message, this.statusCode});
}

class CacheException implements Exception {
  final String message;
  CacheException({required this.message});
}

class SocketException implements Exception {
  final String message;
  SocketException({required this.message});
}
