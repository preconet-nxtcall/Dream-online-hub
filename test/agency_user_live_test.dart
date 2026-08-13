import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  group('Live PHP & Node.js Backend Integration Test', () {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://telewiz.in/officemanage/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    test('1. Live Agency Login (agency@gmail.com / password: 12345)', () async {
      final res = await dio.post(
        'api.php',
        data: {
          'action': 'login',
          'email': 'agency@gmail.com',
          'password': '12345',
        },
      );
      print('\n[LIVE AGENCY LOGIN] Status: ${res.statusCode}');
      print('Data: ${res.data}');
      expect(res.data['success'], isTrue);
      expect(res.data['user']['role'], equals('AGENCY'));
    });

    test('2. Live User Login (user@gmail.com & sample@gmail.com / password: 12345)', () async {
      final emailsToTry = ['user@gmail.com', 'sample@gmail.com'];
      dynamic userData;

      for (final email in emailsToTry) {
        try {
          final res = await dio.post(
            'api.php',
            options: Options(validateStatus: (status) => status != null && status < 500),
            data: {
              'action': 'login',
              'email': email,
              'password': '12345',
            },
          );
          print('\n[LIVE USER LOGIN] Email: $email | Status: ${res.statusCode} | Data: ${res.data}');
          if (res.data is Map<String, dynamic> && res.data['success'] == true) {
            userData = res.data['user'];
            break;
          }
        } catch (e) {
          print('[LIVE USER LOGIN ERROR] Email: $email -> $e');
        }
      }

      expect(userData, isNotNull);
    });

    test('3. Live get_by_agency_id endpoint test', () async {
      final res = await dio.post(
        'api.php',
        data: {
          'action': 'get_by_agency_id',
          'agency_id': '1',
        },
      );
      print('\n[LIVE GET_BY_AGENCY_ID] Status: ${res.statusCode}');
      print('Data: ${res.data}');
      expect(res.statusCode, equals(200));
      expect(res.data['success'], isTrue);
    });
  });
}
