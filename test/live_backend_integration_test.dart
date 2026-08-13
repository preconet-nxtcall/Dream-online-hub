import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  group('Live PHP Backend Action Discovery for sample@gmail.com', () {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://telewiz.in/officemanage/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    test('Live Action Discovery Probe', () async {
      final profileActions = [
        'update_user',
        'delete_user',
        'read_users',
        'get_by_agency_id',
      ];

      for (final actionName in profileActions) {
        try {
          final response = await dio.post(
            'api.php',
            options: Options(validateStatus: (status) => status != null && status < 500),
            data: {
              'action': actionName,
              'id': 24,
              'name': 'Test User',
              'email': 'sample@gmail.com',
              'mob': '9876543210',
              'agency_id': '1',
            },
          );
          print('\n[PROFILE PROBE] Action "$actionName" Status: ${response.statusCode}, Body: ${response.data}');
        } catch (e) {
          print('[ERROR] "$actionName" -> $e');
        }
      }
    });
  });
}
