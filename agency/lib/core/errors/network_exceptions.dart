import 'package:dio/dio.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errorData;

  const NetworkException({
    required this.message,
    this.statusCode,
    this.errorData,
  });

  factory NetworkException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request to API server was cancelled.');
      case DioExceptionType.connectionTimeout:
        return const NetworkException(message: 'Connection timeout with API server. Please check your internet connection.');
      case DioExceptionType.sendTimeout:
        return const NetworkException(message: 'Send timeout with API server. Request took too long.');
      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: 'Receive timeout in connection with API server.');
      case DioExceptionType.badCertificate:
        return const NetworkException(message: 'Security certificate verification failed.');
      case DioExceptionType.connectionError:
        return const NetworkException(message: 'No internet connection. Please verify your network setup.');
      case DioExceptionType.badResponse:
        return NetworkException._handleBadResponse(dioException.response);
      case DioExceptionType.unknown:
      default:
        if (dioException.message != null && dioException.message!.contains('SocketException')) {
          return const NetworkException(message: 'No Internet Connection');
        }
        return NetworkException(
          message: dioException.message ?? 'An unexpected network error occurred.',
        );
    }
  }

  static NetworkException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    dynamic data = response?.data;
    String errorMessage = 'Received invalid response from server ($statusCode).';

    if (data is Map<String, dynamic>) {
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        errorMessage = data['message'].toString();
      } else if (data['error'] != null && data['error'].toString().isNotEmpty) {
        errorMessage = data['error'].toString();
      } else if (data['errors'] != null) {
        errorMessage = data['errors'].toString();
      }
    }

    switch (statusCode) {
      case 400:
        return NetworkException(message: errorMessage, statusCode: 400, errorData: data);
      case 401:
        return NetworkException(message: errorMessage.isEmpty ? 'Session expired. Please log in again.' : errorMessage, statusCode: 401, errorData: data);
      case 403:
        return NetworkException(message: errorMessage.isEmpty ? 'Access forbidden. You do not have permission.' : errorMessage, statusCode: 403, errorData: data);
      case 404:
        return NetworkException(message: errorMessage.isEmpty ? 'Requested resource not found on server.' : errorMessage, statusCode: 404, errorData: data);
      case 409:
        return NetworkException(message: errorMessage.isEmpty ? 'Conflict occurred on the server.' : errorMessage, statusCode: 409, errorData: data);
      case 422:
        return NetworkException(message: errorMessage.isEmpty ? 'Validation error occurred.' : errorMessage, statusCode: 422, errorData: data);
      case 500:
        return NetworkException(message: 'Internal server error occurred. Please try again later.', statusCode: 500, errorData: data);
      case 502:
        return NetworkException(message: 'Bad gateway. The server received an invalid response.', statusCode: 502, errorData: data);
      case 503:
        return NetworkException(message: 'Service unavailable. Server is under maintenance.', statusCode: 503, errorData: data);
      default:
        return NetworkException(message: errorMessage, statusCode: statusCode, errorData: data);
    }
  }

  @override
  String toString() => 'NetworkException(statusCode: $statusCode, message: $message)';
}
