import 'package:flutter_test/flutter_test.dart';
import 'package:agency_user_app/models/agency/agency_model.dart';
import 'package:agency_user_app/models/agency/agency_user_item_model.dart';
import 'package:agency_user_app/providers/agency_provider.dart';
import 'package:agency_user_app/repositories/agency_repository.dart';

class MockAgencyRepository implements AgencyRepository {
  @override
  Future<AgencyModel> getAgencyDetails(String agencyId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<AgencyUserItem>> fetchAgencyUsers({
    required int page,
    required int limit,
    String? searchQuery,
  }) async {
    return [
      AgencyUserItem(
        id: 'usr_1',
        name: 'Sarah Connor',
        email: 'sarah.connor@example.com',
        unreadCount: 3,
        isOnline: true,
        lastMessage: 'Hello support',
      ),
      AgencyUserItem(
        id: 'usr_2',
        name: 'Michael Vance',
        email: 'm.vance@techcorp.io',
        unreadCount: 0,
        isOnline: false,
        lastMessage: 'All set!',
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AgencyProvider Tests', () {
    late AgencyProvider agencyProvider;

    setUp(() {
      agencyProvider = AgencyProvider(agencyRepository: MockAgencyRepository());
    });

    test('fetchUsers populates user list correctly', () async {
      expect(agencyProvider.users, isEmpty);
      await agencyProvider.fetchUsers();
      expect(agencyProvider.users.length, equals(2));
      expect(agencyProvider.users.first.name, equals('Sarah Connor'));
      expect(agencyProvider.users.first.unreadCount, equals(3));
      expect(agencyProvider.totalUnreadCount, equals(3));
      expect(agencyProvider.onlineUsersCount, equals(1));
    });

    test('filter tabs filter users correctly', () async {
      await agencyProvider.fetchUsers();

      expect(agencyProvider.filteredUsers.length, equals(2));

      agencyProvider.setFilter(AgencyUserFilterTab.unread);
      expect(agencyProvider.filteredUsers.length, equals(1));
      expect(agencyProvider.filteredUsers.first.id, equals('usr_1'));

      agencyProvider.setFilter(AgencyUserFilterTab.online);
      expect(agencyProvider.filteredUsers.length, equals(1));
      expect(agencyProvider.filteredUsers.first.id, equals('usr_1'));
    });

    test('markUserAsRead clears unread count for target user', () async {
      await agencyProvider.fetchUsers();
      expect(agencyProvider.users.first.unreadCount, equals(3));

      agencyProvider.markUserAsRead('usr_1');
      expect(agencyProvider.users.first.unreadCount, equals(0));
      expect(agencyProvider.totalUnreadCount, equals(0));
    });

    test('updateUserLastMessage updates preview message for target user', () async {
      await agencyProvider.fetchUsers();
      agencyProvider.updateUserLastMessage('usr_1', 'Latest updated message');

      expect(agencyProvider.users.first.lastMessage, equals('Latest updated message'));
      expect(agencyProvider.users.first.unreadCount, equals(0));
    });
  });
}
