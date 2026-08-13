import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Verify both numeric agency_id ("23") and unique code ("AGENCY-23") match assigned users', () {
    final dbRows = [
      {'id': 1,  'name': 'Admin',          'email': 'admin@gmail.com',       'type': 'ADMIN',    'agency_id': '',            'agency_unq_id': 'ADMIN-1'},
      {'id': 22, 'name': 'Jhon Smith',     'email': 'user@gmail.com',        'type': 'USER',     'agency_id': '1',           'agency_unq_id': ''},
      {'id': 23, 'name': 'Ritdz 4k',        'email': 'agency@gmail.com',      'type': 'AGENCY',   'agency_id': '',            'agency_unq_id': 'AGENCY-23'},
      {'id': 24, 'name': 'Lorem Ipsum',    'email': 'sample@gmail.com',      'type': 'USER',     'agency_id': '23',          'agency_unq_id': ''},
      {'id': 25, 'name': 'Code Test User', 'email': 'codeuser@gmail.com',    'type': 'USER',     'agency_id': 'AGENCY-23',   'agency_unq_id': ''},
      {'id': 26, 'name': 'Test User',      'email': 'testuser99@gmail.com',  'type': 'USER',     'agency_id': '',            'agency_unq_id': ''},
      {'id': 27, 'name': 'David Beckham',  'email': 'david@gmail.com',       'type': 'USER',     'agency_id': '1',           'agency_unq_id': ''},
    ];

    // Logged in Agency: agency@gmail.com -> id: 23, agency_unq_id: AGENCY-23
    final rawAgencyId = '23';
    final cleanAgencyId = rawAgencyId.replaceAll(RegExp(r'^\D+'), '');

    final filtered = dbRows.where((item) {
      final type = (item['type'] ?? '').toString().toUpperCase();
      if (type != 'USER') return false;

      if (rawAgencyId.isNotEmpty) {
        final rawUserAgency = (item['agency_id'] ?? item['emp_id'] ?? '').toString().trim();
        if (rawUserAgency.isEmpty) return false;

        final userAgencyClean = rawUserAgency.replaceAll(RegExp(r'^\D+'), '');
        final currentAgencyClean = cleanAgencyId;
        final fullAgencyUnqId = 'AGENCY-$cleanAgencyId';

        final isMatched = rawUserAgency == rawAgencyId ||
            rawUserAgency == fullAgencyUnqId ||
            (userAgencyClean.isNotEmpty && userAgencyClean == currentAgencyClean);

        if (!isMatched) return false;
      }
      return true;
    }).toList();

    print('\n================ MATCHED USERS FOR AGENCY 23 / AGENCY-23 ================');
    for (final u in filtered) {
      print(' -> ID: ${u['id']} | Name: ${u['name']} | Email: ${u['email']} | Column agency_id: "${u['agency_id']}"');
    }
    print('=========================================================================\n');

    expect(filtered.length, equals(2));
    expect(filtered.any((u) => u['email'] == 'sample@gmail.com'), isTrue);
    expect(filtered.any((u) => u['email'] == 'codeuser@gmail.com'), isTrue);
    expect(filtered.any((u) => u['email'] == 'user@gmail.com'), isFalse);
  });
}
