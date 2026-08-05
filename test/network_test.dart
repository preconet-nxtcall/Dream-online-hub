import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:agency_user_app/core/errors/network_exceptions.dart';
import 'package:agency_user_app/models/dto/auth/login_request_dto.dart';
import 'package:agency_user_app/models/dto/auth/login_response_dto.dart';
import 'package:agency_user_app/models/dto/auth/refresh_token_request_dto.dart';
import 'package:agency_user_app/models/dto/auth/refresh_token_response_dto.dart';
import 'package:agency_user_app/models/dto/chat/send_message_request_dto.dart';
import 'package:agency_user_app/models/dto/chat/chat_message_dto.dart';
import 'package:agency_user_app/models/dto/agency/agency_users_request_dto.dart';
import 'package:agency_user_app/models/dto/agency/agency_users_response_dto.dart';
import 'package:agency_user_app/models/dto/common/api_response_dto.dart';

void main() {
  group('Network Exceptions Tests', () {
    test('NetworkException maps Dio connection timeout correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final networkException = NetworkException.fromDioException(dioException);
      expect(networkException.message, contains('Connection timeout'));
    });

    test('NetworkException maps 401 Unauthorized status code correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'message': 'Invalid JWT token'},
        ),
      );

      final networkException = NetworkException.fromDioException(dioException);
      expect(networkException.statusCode, equals(401));
      expect(networkException.message, equals('Invalid JWT token'));
    });

    test('NetworkException maps 500 Internal Server Error correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
      );

      final networkException = NetworkException.fromDioException(dioException);
      expect(networkException.statusCode, equals(500));
      expect(networkException.message, contains('Internal server error'));
    });
  });

  group('DTO Serialization Tests', () {
    test('LoginRequestDto serializes to JSON correctly', () {
      const dto = LoginRequestDto(
        email: 'test@example.com',
        password: 'password123',
        role: 'agency',
      );

      final json = dto.toJson();
      expect(json['email'], equals('test@example.com'));
      expect(json['password'], equals('password123'));
      expect(json['role'], equals('agency'));
    });

    test('LoginResponseDto parses JSON correctly', () {
      final json = {
        'access_token': 'access_123',
        'refresh_token': 'refresh_456',
        'expires_in': 3600,
        'user': {
          'id': 'usr_1',
          'email': 'admin@agency.com',
          'name': 'Agency Admin',
          'role': 'agency',
        },
      };

      final dto = LoginResponseDto.fromJson(json);
      expect(dto.accessToken, equals('access_123'));
      expect(dto.refreshToken, equals('refresh_456'));
      expect(dto.user['name'], equals('Agency Admin'));
    });

    test('RefreshTokenRequestDto and ResponseDto serialize correctly', () {
      const req = RefreshTokenRequestDto(refreshToken: 'ref_789');
      expect(req.toJson()['refresh_token'], equals('ref_789'));

      final res = RefreshTokenResponseDto.fromJson({
        'access_token': 'new_access_000',
        'expires_in': 3600,
      });
      expect(res.accessToken, equals('new_access_000'));
    });

    test('SendMessageRequestDto serializes to JSON correctly', () {
      const dto = SendMessageRequestDto(
        receiverId: 'usr_100',
        message: 'Hello client!',
        type: 'text',
      );

      final json = dto.toJson();
      expect(json['receiver_id'], equals('usr_100'));
      expect(json['message'], equals('Hello client!'));
    });

    test('ChatMessageDto converts to Domain ChatMessageModel correctly', () {
      final json = {
        'id': 'msg_1',
        'sender_id': 'usr_100',
        'receiver_id': 'me',
        'message': 'Welcome',
        'timestamp': '2026-08-03T10:00:00.000Z',
        'status': 'seen',
        'type': 'text',
      };

      final dto = ChatMessageDto.fromJson(json);
      final model = dto.toDomainModel(currentUserId: 'me');

      expect(model.id, equals('msg_1'));
      expect(model.message, equals('Welcome'));
      expect(model.isMe, isFalse);
    });

    test('AgencyUsersRequestDto and ResponseDto parse paginated user data', () {
      const req = AgencyUsersRequestDto(page: 1, limit: 10, searchQuery: 'Sarah');
      expect(req.toQueryParameters()['query'], equals('Sarah'));

      final resJson = {
        'total': 1,
        'page': 1,
        'limit': 10,
        'data': [
          {
            'id': 'usr_1',
            'name': 'Sarah Connor',
            'email': 'sarah@example.com',
          }
        ],
      };

      final res = AgencyUsersResponseDto.fromJson(resJson);
      expect(res.users.length, equals(1));
      expect(res.users.first.name, equals('Sarah Connor'));
    });

    test('ApiResponseDto parses generic response wrapper', () {
      final json = {
        'success': true,
        'status_code': 200,
        'message': 'Operation successful',
        'data': {'id': '123'},
      };

      final responseDto = ApiResponseDto<Map<String, dynamic>>.fromJson(
        json,
        (dataJson) => dataJson as Map<String, dynamic>,
      );

      expect(responseDto.success, isTrue);
      expect(responseDto.message, equals('Operation successful'));
      expect(responseDto.data?['id'], equals('123'));
    });
  });
}
