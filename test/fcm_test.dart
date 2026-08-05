import 'package:flutter_test/flutter_test.dart';
import 'package:agency_user_app/notifications/fcm_deep_link_router.dart';
import 'package:agency_user_app/notifications/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FCMDeepLinkRouter Payload Tests', () {
    test('Parses chat notification payload correctly', () {
      final payload = {
        'type': 'chat',
        'user_id': 'usr_100',
      };

      final target = FCMDeepLinkRouter.parsePayload(payload);
      expect(target, isNotNull);
      expect(target?.routePath, equals('/chat/usr_100'));
      expect(target?.userId, equals('usr_100'));
    });

    test('Parses agency dashboard notification payload correctly', () {
      final payload = {
        'type': 'agency_dashboard',
      };

      final target = FCMDeepLinkRouter.parsePayload(payload);
      expect(target, isNotNull);
      expect(target?.routePath, equals('/agency-dashboard'));
    });

    test('Parses user dashboard notification payload correctly', () {
      final payload = {
        'type': 'user_dashboard',
      };

      final target = FCMDeepLinkRouter.parsePayload(payload);
      expect(target, isNotNull);
      expect(target?.routePath, equals('/user-dashboard'));
    });

    test('Parses game arena notification payload correctly', () {
      final payload = {
        'type': 'game_arena',
        'game_id': 'milan_morning',
      };

      final target = FCMDeepLinkRouter.parsePayload(payload);
      expect(target, isNotNull);
      expect(target?.routePath, equals('/game-arena/milan_morning'));
      expect(target?.gameId, equals('milan_morning'));
    });

    test('Parses stringified JSON notification payload', () {
      const jsonString = '{"type":"chat","sender_id":"usr_200"}';

      final target = FCMDeepLinkRouter.parsePayload(jsonString);
      expect(target, isNotNull);
      expect(target?.routePath, equals('/chat/usr_200'));
      expect(target?.userId, equals('usr_200'));
    });

    test('Returns default route for empty/null payload', () {
      final target = FCMDeepLinkRouter.parsePayload(null);
      expect(target, isNull);
    });
  });

  group('NotificationService Singleton Test', () {
    test('NotificationService singleton returns valid instance', () {
      final service = NotificationService.instance;
      expect(service, isNotNull);
      expect(service, equals(NotificationService.instance));
    });
  });
}
