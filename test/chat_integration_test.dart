import 'package:flutter_test/flutter_test.dart';
import 'package:agency_user_app/models/chat/chat_message_model.dart';
import 'package:agency_user_app/models/dto/chat/chat_message_dto.dart';

void main() {
  group('Chat Real-Time Backend Logic & Status Flow Verification', () {
    test('Message Status Lifecycle Progression (sending -> queued -> sent -> delivered -> read)', () async {
      // 1. Initial optimistic message
      var msg = ChatMessageModel(
        id: 'temp-123',
        senderId: 'user-1@example.com',
        receiverId: 'agent-alice',
        message: 'Hello Support!',
        timestamp: DateTime.parse('2026-08-08T12:00:00.000Z'),
        isMe: true,
        status: 'sending',
        type: 'text',
      );

      expect(msg.status, equals('sending'));

      // 2. Server emits message:queued ack
      final queuedAck = {
        'status': 'queued',
        'messageId': 'temp-123',
        'conversationId': 'conv-agent-alice-user-1',
        'createdAt': '2026-08-08T12:00:00.100Z',
      };
      if (queuedAck['status'] == 'queued') {
        msg = msg.copyWith(status: 'queued');
      }
      expect(msg.status, equals('queued'));

      // 3. Server worker writes to DB and emits message:sent ack with real _id
      final sentAck = {
        '_id': 'msg-mongo-db-67890',
        'conversationId': 'conv-agent-alice-user-1',
        'status': 'sent',
        'createdAt': '2026-08-08T12:00:00.500Z',
      };
      msg = msg.copyWith(
        id: sentAck['_id'],
        status: sentAck['status'],
        timestamp: DateTime.parse(sentAck['createdAt']!),
      );
      expect(msg.id, equals('msg-mongo-db-67890'));
      expect(msg.status, equals('sent'));

      // 4. Recipient device receives message and sends delivery receipt -> server relays message:delivered
      final deliveredRelay = {
        'type': 'delivered',
        'messageId': 'msg-mongo-db-67890',
        'conversationId': 'conv-agent-alice-user-1',
        'deliveredAt': '2026-08-08T12:00:01.000Z',
      };
      if (deliveredRelay['messageId'] == msg.id) {
        msg = msg.copyWith(status: 'delivered');
      }
      expect(msg.status, equals('delivered'));

      // 5. Recipient opens chat screen -> server relays message:read
      final readRelay = {
        'type': 'read',
        'conversationId': 'conv-agent-alice-user-1',
        'readBy': 'agent-alice',
        'messageIds': ['msg-mongo-db-67890'],
        'readAt': '2026-08-08T12:00:02.000Z',
      };
      final messageIds = (readRelay['messageIds'] as List).cast<String>();
      if (messageIds.contains(msg.id)) {
        msg = msg.copyWith(status: 'read');
      }
      expect(msg.status, equals('read'));
    });

    test('Incoming message:new DTO parsing and model mapping', () {
      final incomingPayload = {
        '_id': 'msg-incoming-999',
        'conversationId': 'conv-agent-alice-user-1',
        'senderId': 'agent-alice@example.com',
        'senderType': 'agent',
        'type': 'text',
        'text': 'How can I assist you today?',
        'status': 'sent',
        'createdAt': '2026-08-08T12:00:03.000Z',
      };

      final dto = ChatMessageDto.fromJson(incomingPayload, chatEmailId: 'user-1@example.com');
      final model = dto.toChatModel(chatEmailId: 'user-1@example.com');

      expect(model.id, equals('msg-incoming-999'));
      expect(model.isMe, isFalse);
      expect(model.senderId, equals('agent-alice@example.com'));
      expect(model.message, equals('How can I assist you today?'));
    });
  });
}
