import 'package:flutter_test/flutter_test.dart';
import 'package:agency_app/models/agency/agency_user_item_model.dart';

void main() {
  group('Agency Notification & 7-Day Filter Tests', () {
    test('Filter clients by 7 days active window', () {
      final now = DateTime.now();
      final recentClient = AgencyUserItem(
        id: '1',
        name: 'Recent User',
        email: 'recent@test.com',
        unreadCount: 3,
        lastActiveTime: now.subtract(const Duration(days: 2)),
      );

      final oldClient = AgencyUserItem(
        id: '2',
        name: 'Old User',
        email: 'old@test.com',
        unreadCount: 5,
        lastActiveTime: now.subtract(const Duration(days: 10)),
      );

      final allClients = [recentClient, oldClient];
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final last7DaysUnread = allClients.where((u) {
        if (u.unreadCount <= 0) return false;
        if (u.lastActiveTime == null) return true;
        return u.lastActiveTime!.isAfter(sevenDaysAgo);
      }).toList();

      expect(last7DaysUnread.length, equals(1));
      expect(last7DaysUnread.first.name, equals('Recent User'));
    });

    test('Header Notification Count and 99+ formatting', () {
      int totalUnread = 50;
      int pendingRecharges = 65;
      int totalNotifications = totalUnread + pendingRecharges;

      String badgeText = totalNotifications > 99 ? '99+' : '$totalNotifications';

      expect(totalNotifications, equals(115));
      expect(badgeText, equals('99+'));

      // Test lower count
      totalUnread = 5;
      pendingRecharges = 3;
      totalNotifications = totalUnread + pendingRecharges;
      badgeText = totalNotifications > 99 ? '99+' : '$totalNotifications';

      expect(totalNotifications, equals(8));
      expect(badgeText, equals('8'));
    });

    test('Read All resets unread count to 0', () {
      final clients = [
        AgencyUserItem(id: '1', name: 'User 1', email: '1@test.com', unreadCount: 4),
        AgencyUserItem(id: '2', name: 'User 2', email: '2@test.com', unreadCount: 2),
      ];

      final clearedClients = clients.map((c) => c.copyWith(unreadCount: 0)).toList();
      final totalUnread = clearedClients.fold<int>(0, (sum, item) => sum + item.unreadCount);

      expect(totalUnread, equals(0));
    });
  });
}
