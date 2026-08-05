import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:agency_user_app/models/agency/agency_user_item_model.dart';
import 'package:agency_user_app/models/chat/chat_message_model.dart';
import 'package:agency_user_app/models/common/user_model.dart';
import 'package:agency_user_app/storage/local_storage_repository.dart';
import 'package:agency_user_app/storage/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late HiveLocalStorageService storageService;
  late LocalStorageRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);

    storageService = HiveLocalStorageService();
    await storageService.init(customPath: tempDir.path);
    repository = LocalStorageRepositoryImpl(storageService: storageService);
  });

  tearDown(() async {
    await storageService.clearAllBoxes();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('User & Token Storage Tests', () {
    test('Saves and reads logged user correctly', () async {
      final user = UserModel(
        id: 'usr_100',
        email: 'agency_admin@apex.com',
        name: 'Apex Admin',
        role: 'agency',
      );

      await repository.saveUser(user);
      final retrieved = repository.getUser();

      expect(retrieved, isNotNull);
      expect(retrieved?.id, equals('usr_100'));
      expect(retrieved?.name, equals('Apex Admin'));
      expect(retrieved?.role, equals('agency'));
    });

    test('Saves and retrieves access and refresh tokens', () async {
      await repository.saveTokens(
        accessToken: 'access_jwt_123',
        refreshToken: 'refresh_jwt_456',
      );

      expect(repository.getAccessToken(), equals('access_jwt_123'));
      expect(repository.getRefreshToken(), equals('refresh_jwt_456'));
    });

    test('clearAuthData deletes user and tokens', () async {
      final user = UserModel(id: '1', email: 'e', name: 'n', role: 'r');
      await repository.saveUser(user);
      await repository.saveTokens(accessToken: 't1', refreshToken: 't2');

      await repository.clearAuthData();

      expect(repository.getUser(), isNull);
      expect(repository.getAccessToken(), isNull);
      expect(repository.getRefreshToken(), isNull);
    });
  });

  group('Chats & Messages Storage Tests', () {
    test('Caches and retrieves conversation messages', () async {
      final messages = [
        ChatMessageModel(
          id: 'msg_1',
          senderId: 'client_1',
          receiverId: 'me',
          message: 'Hello Support!',
          timestamp: DateTime.now(),
          isMe: false,
        ),
      ];

      await repository.saveMessages('client_1', messages);
      final cached = repository.getCachedMessages('client_1');

      expect(cached.length, equals(1));
      expect(cached.first.id, equals('msg_1'));
      expect(cached.first.message, equals('Hello Support!'));
    });

    test('Caches and retrieves recent chats list', () async {
      final recentChats = [
        AgencyUserItem(
          id: 'u1',
          name: 'Sarah Connor',
          email: 'sarah@test.com',
          unreadCount: 3,
        ),
      ];

      await repository.saveRecentChats(recentChats);
      final cached = repository.getCachedRecentChats();

      expect(cached.length, equals(1));
      expect(cached.first.name, equals('Sarah Connor'));
      expect(cached.first.unreadCount, equals(3));
    });
  });

  group('Theme Mode & Unread Count Tests', () {
    test('Saves and reads theme mode preference', () async {
      expect(repository.getThemeMode(), equals('light'));

      await repository.saveThemeMode('dark');
      expect(repository.getThemeMode(), equals('dark'));
    });

    test('Sets, increments, and clears unread count', () async {
      expect(repository.getUnreadCount('usr_50'), equals(0));

      await repository.setUnreadCount('usr_50', 2);
      expect(repository.getUnreadCount('usr_50'), equals(2));

      await repository.incrementUnread('usr_50');
      expect(repository.getUnreadCount('usr_50'), equals(3));

      await repository.clearUnreadCount('usr_50');
      expect(repository.getUnreadCount('usr_50'), equals(0));
    });
  });

  group('Offline Queue Storage Tests', () {
    test('Saves and retrieves offline pending messages queue', () async {
      final queue = [
        {'event': 'send_message', 'payload': {'message': 'Offline Msg 1'}},
        {'event': 'send_message', 'payload': {'message': 'Offline Msg 2'}},
      ];

      await repository.saveOfflineQueue(queue);
      final retrieved = repository.getOfflineQueue();

      expect(retrieved.length, equals(2));
      expect(retrieved.first['payload']['message'], equals('Offline Msg 1'));

      await repository.clearOfflineQueue();
      expect(repository.getOfflineQueue(), isEmpty);
    });
  });
}
