import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  test('Find assigned users for agency@gmail.com on Live PHP Server', () async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://telewiz.in/officemanage/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    print('\n================ LIVE AGENCY ASSIGNED USERS QUERY ================');

    // Step 1: Login as agency@gmail.com
    final loginRes = await dio.post('api.php', data: {
      'action': 'login',
      'email': 'agency@gmail.com',
      'password': '12345',
    });

    print('[LOGIN RESPONSE]: Status: ${loginRes.statusCode}');
    print('Data: ${loginRes.data}');

    final userData = loginRes.data['user'];
    final agencyId = userData['id']?.toString() ?? '23';
    final agencyUnqId = (userData['agency_unq_id'] ?? userData['agency_id'] ?? '').toString();

    print('\n[LOGGED IN AGENCY DETAILS]:');
    print('ID: $agencyId');
    print('Name: ${userData['name']}');
    print('Email: ${userData['email']}');
    print('Role: ${userData['role']}');
    print('Agency Unique ID: $agencyUnqId');

    // Step 2: Test get_by_agency_id with agencyId (23)
    final getByAgencyRes = await dio.post('api.php', data: {
      'action': 'get_by_agency_id',
      'agency_id': agencyId,
    });
    print('\n[GET_BY_AGENCY_ID with agency_id="$agencyId"]:');
    print('Response: ${getByAgencyRes.data}');

    // Step 3: Test get_by_agency_id with AGENCY-23 or 1
    final getByAgencyUnqRes = await dio.post('api.php', data: {
      'action': 'get_by_agency_id',
      'agency_id': 'AGENCY-$agencyId',
    });
    print('\n[GET_BY_AGENCY_ID with agency_id="AGENCY-$agencyId"]:');
    print('Response: ${getByAgencyUnqRes.data}');

    // Step 4: Fetch read_users to examine all records and matching agency_id fields
    final readUsersRes = await dio.post('api.php', data: {
      'action': 'read_users',
    });
    print('\n[ALL USERS FROM read_users]:');
    final allUsers = readUsersRes.data['data'] as List? ?? [];
    for (final u in allUsers) {
      print(' - ID: ${u['id']} | Name: ${u['name']} | Email: ${u['email']} | Mob: ${u['mob']} | Type: ${u['type']} | agency_id: ${u['agency_id']} | agency_unq_id: ${u['agency_unq_id']}');
    }

    print('==================================================================\n');
  });
}
