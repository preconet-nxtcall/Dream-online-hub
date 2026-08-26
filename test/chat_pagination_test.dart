import 'package:flutter_test/flutter_test.dart';
import 'package:agency_user_app/models/chat/chat_message_model.dart';
import 'package:agency_user_app/providers/chat_provider.dart';
import 'package:agency_user_app/repositories/chat_repository.dart';

class MockChatRepository implements ChatRepository {
  List<ChatMessageModel> cachedMessagesToReturn = [];
  List<ChatMessageModel> serverMessagesToReturn = [];
  List<ChatMessageModel> olderMessagesToReturn = [];

  String? lastFetchedConversationId;
  String? lastFetchedCursor;
  int? lastFetchedLimit;

  @override
  List<ChatMessageModel> getCachedMessages(String conversationId) {
    return List.from(cachedMessagesToReturn);
  }

  @override
  Future<List<ChatMessageModel>> fetchMessages(
    String conversationId, {
    String? recipientId,
    int limit = 35,
    String? cursor,
  }) async {
    lastFetchedConversationId = conversationId;
    lastFetchedCursor = cursor;
    lastFetchedLimit = limit;

    if (cursor != null) {
      return List.from(olderMessagesToReturn);
    }
    return List.from(serverMessagesToReturn);
  }

  @override
  Future<void> saveLocalMessages(String conversationId, List<ChatMessageModel> messages) async {}

  @override
  Future<Map<String, dynamic>> loginToChat(String emailId, String password) async => {};

  @override
  Future<String?> getChatToken() async => 'mock_token';

  @override
  Future<String?> getChatEmailId() async => 'user@test.com';

  @override
  Future<String?> getChatAgentId() async => 'AGENCY-23';

  @override
  Future<String?> getChatUserRole() async => 'user';

  @override
  Future<List<Map<String, dynamic>>> fetchConversations() async => [];

  @override
  Future<Map<String, dynamic>> getPresignedVoiceUrl(String conversationId, {String mimeType = 'audio/webm'}) async => {};

  @override
  Future<Map<String, dynamic>> getPresignedImageUrl(String conversationId, {String mimeType = 'image/png'}) async => {};

  @override
  Future<bool> uploadMediaFile(String uploadUrl, String filePath, {String mimeType = 'application/octet-stream', dynamic onProgress}) async => true;

  @override
  Future<String?> getPlayVoiceUrl(String fileKey) async => null;

  @override
  Future<String?> getPlayImageUrl(String fileKey) async => null;
}

void main() {
  group('WhatsApp-Style Chat Pagination Tests', () {
    late MockChatRepository mockRepo;
    late ChatProvider chatProvider;

    setUp(() {
      mockRepo = MockChatRepository();
      chatProvider = ChatProvider(chatRepository: mockRepo);
    });

    test('1. Initial Load immediately retrieves local cache, then fetches 35 messages', () async {
      final now = DateTime.now();

      // Seed local cache with 2 messages
      mockRepo.cachedMessagesToReturn = [
        ChatMessageModel(
          id: 'msg_cached_1',
          senderId: 'agency@test.com',
          receiverId: 'user@test.com',
          message: 'Cached Hello',
          timestamp: now.subtract(const Duration(minutes: 10)),
          isMe: false,
        ),
      ];

      // Seed server with 35 fresh messages
      mockRepo.serverMessagesToReturn = List.generate(
        35,
        (i) => ChatMessageModel(
          id: 'msg_server_$i',
          senderId: 'agency@test.com',
          receiverId: 'user@test.com',
          message: 'Server msg $i',
          timestamp: now.subtract(Duration(minutes: 35 - i)),
          isMe: false,
        ),
      );

      // Act
      final fetchFuture = chatProvider.fetchMessages(
        'conv-AGENCY-23-user@test.com',
        recipientId: 'agency@test.com',
        limit: 35,
      );

      // Verify cached messages loaded immediately
      expect(chatProvider.messages.length, equals(1));
      expect(chatProvider.messages.first.message, equals('Cached Hello'));

      // Await network sync
      await fetchFuture;

      // Verify limit = 35 was sent to server
      expect(mockRepo.lastFetchedLimit, equals(35));
      expect(mockRepo.lastFetchedCursor, isNull);

      // Verify final merged messages
      expect(chatProvider.messages.length, equals(35));
      expect(chatProvider.hasMoreMessages, isTrue);
    });

    test('2. Scroll up pagination fetches older 35 messages using cursor ISO timestamp', () async {
      final now = DateTime.now();

      // Initial state has 35 messages
      final initialMsgs = List.generate(
        35,
        (i) => ChatMessageModel(
          id: 'msg_batch1_$i',
          senderId: 'agency@test.com',
          receiverId: 'user@test.com',
          message: 'Batch 1 msg $i',
          timestamp: now.subtract(Duration(minutes: 35 - i)),
          isMe: false,
        ),
      );

      mockRepo.serverMessagesToReturn = initialMsgs;

      await chatProvider.fetchMessages(
        'conv-AGENCY-23-user@test.com',
        recipientId: 'agency@test.com',
        limit: 35,
      );

      expect(chatProvider.messages.length, equals(35));
      final oldestMsgTimestamp = chatProvider.messages.first.timestamp.toIso8601String();

      // Prepare 35 older messages to return on scroll up cursor
      mockRepo.olderMessagesToReturn = List.generate(
        35,
        (i) => ChatMessageModel(
          id: 'msg_batch2_$i',
          senderId: 'agency@test.com',
          receiverId: 'user@test.com',
          message: 'Batch 2 older msg $i',
          timestamp: now.subtract(Duration(minutes: 100 - i)),
          isMe: false,
        ),
      );

      // Act: User scrolls up, triggering loadMoreMessages()
      await chatProvider.loadMoreMessages(limit: 35);

      // Verify cursor matches oldest message ISO date string
      expect(mockRepo.lastFetchedCursor, equals(oldestMsgTimestamp));
      expect(mockRepo.lastFetchedLimit, equals(35));

      // Verify older messages prepended cleanly (35 + 35 = 70 total)
      expect(chatProvider.messages.length, equals(70));
      expect(chatProvider.messages.first.id, equals('msg_batch2_0'));
    });

    test('3. hasMoreMessages becomes false when older messages returned is less than limit', () async {
      final now = DateTime.now();

      mockRepo.serverMessagesToReturn = List.generate(
        35,
        (i) => ChatMessageModel(
          id: 'msg_$i',
          senderId: 'agency@test.com',
          receiverId: 'user@test.com',
          message: 'msg $i',
          timestamp: now.subtract(Duration(minutes: 35 - i)),
          isMe: false,
        ),
      );

      await chatProvider.fetchMessages(
        'conv-AGENCY-23-user@test.com',
        recipientId: 'agency@test.com',
        limit: 35,
      );

      // Only 5 older messages remaining on server
      mockRepo.olderMessagesToReturn = List.generate(
        5,
        (i) => ChatMessageModel(
          id: 'older_msg_$i',
          senderId: 'agency@test.com',
          receiverId: 'user@test.com',
          message: 'older $i',
          timestamp: now.subtract(Duration(minutes: 50 - i)),
          isMe: false,
        ),
      );

      await chatProvider.loadMoreMessages(limit: 35);

      expect(chatProvider.messages.length, equals(40));
      expect(chatProvider.hasMoreMessages, isFalse);
    });
  });
}
