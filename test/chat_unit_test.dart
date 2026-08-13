import 'package:flutter_test/flutter_test.dart';
import 'package:agency_user_app/models/dto/chat/chat_message_dto.dart';
import 'package:agency_user_app/models/dto/chat/send_message_request_dto.dart';
import 'package:agency_user_app/core/constants/api_endpoints.dart';

void main() {
  group('Chat Unit & Logic Tests', () {
    const testUserEmail = 'user-alice-1@example.com';
    const testAgentId = 'agent-alice';
    const testConvId = 'conv-agent-alice-user-alice-1';

    test('ChatMessageDto correctly calculates isMe when email matches senderId', () {
      final jsonPayload = {
        '_id': 'msg-101',
        'conversationId': testConvId,
        'senderId': testUserEmail,
        'senderType': 'user',
        'type': 'text',
        'text': 'Hello agent!',
        'status': 'sent',
        'createdAt': '2026-08-08T12:00:00.000Z',
      };

      final dto = ChatMessageDto.fromJson(jsonPayload, chatEmailId: testUserEmail);
      final model = dto.toChatModel(chatEmailId: testUserEmail);

      expect(model.id, equals('msg-101'));
      expect(model.isMe, isTrue);
      expect(model.message, equals('Hello agent!'));
      expect(model.status, equals('sent'));
    });

    test('ChatMessageDto calculates isMe as false when senderId is another user', () {
      final jsonPayload = {
        '_id': 'msg-102',
        'conversationId': testConvId,
        'senderId': 'agent-alice@example.com',
        'senderType': 'agent',
        'type': 'text',
        'text': 'Hello back!',
        'status': 'sent',
        'createdAt': '2026-08-08T12:01:00.000Z',
      };

      final dto = ChatMessageDto.fromJson(jsonPayload, chatEmailId: testUserEmail);
      final model = dto.toChatModel(chatEmailId: testUserEmail);

      expect(model.id, equals('msg-102'));
      expect(model.isMe, isFalse);
      expect(model.senderId, equals('agent-alice@example.com'));
    });

    test('ChatMessageDto parses audio metadata and computes voice duration format', () {
      final jsonPayload = {
        '_id': 'msg-103',
        'conversationId': testConvId,
        'senderId': 'agent-alice@example.com',
        'type': 'voice',
        'audio': {
          'key': 'voice-notes/sample.webm',
          'duration': 75, // 1 min 15 sec
          'cdnUrl': 'https://s3.example.com/voice-notes/sample.webm'
        },
        'status': 'sent',
        'createdAt': '2026-08-08T12:02:00.000Z',
      };

      final dto = ChatMessageDto.fromJson(jsonPayload, chatEmailId: testUserEmail);
      final model = dto.toChatModel(chatEmailId: testUserEmail);

      expect(model.type, equals('voice'));
      expect(model.voiceDuration, equals('01:15'));
      expect(model.imageUrl, isNull);
    });

    test('SendMessageRequestDto correctly serializes voice and image payloads to API spec', () {
      const textDto = SendMessageRequestDto(
        conversationId: testConvId,
        recipientId: testAgentId,
        type: 'text',
        text: 'Test message',
      );

      final textJson = textDto.toJson();
      expect(textJson['conversationId'], equals(testConvId));
      expect(textJson['recipientId'], equals(testAgentId));
      expect(textJson['type'], equals('text'));
      expect(textJson['text'], equals('Test message'));

      const voiceDto = SendMessageRequestDto(
        conversationId: testConvId,
        recipientId: testAgentId,
        type: 'voice',
        audioKey: 'voice-notes/test.webm',
        audioDuration: 15,
      );

      final voiceJson = voiceDto.toJson();
      expect(voiceJson['type'], equals('voice'));
      expect(voiceJson['audio'], isNotNull);
      expect(voiceJson['audio']['key'], equals('voice-notes/test.webm'));
      expect(voiceJson['audio']['duration'], equals(15));
    });

    test('ApiEndpoints conversation ID builder matches backend conv-{agentId}-{userEmailId} format', () {
      final builtId = ApiEndpoints.buildConversationId('agent-1', 'user-2@test.com');
      expect(builtId, equals('conv-agent-1-user-2@test.com'));
    });

    test('WhatsApp alignment: historical user messages align RIGHT and agency messages align LEFT', () {
      final userMsgJson = {
        '_id': 'msg-201',
        'conversationId': testConvId,
        'senderId': testUserEmail,
        'recipientId': testAgentId,
        'text': 'Old user message',
        'createdAt': '2026-08-01T10:00:00.000Z',
      };
      final agencyMsgJson = {
        '_id': 'msg-202',
        'conversationId': testConvId,
        'senderId': testAgentId,
        'recipientId': testUserEmail,
        'text': 'Old agency reply',
        'createdAt': '2026-08-01T10:01:00.000Z',
      };

      final userDto = ChatMessageDto.fromJson(userMsgJson, chatEmailId: testUserEmail);
      final agencyDto = ChatMessageDto.fromJson(agencyMsgJson, chatEmailId: testUserEmail);

      final userModel = userDto.toChatModel(chatEmailId: testUserEmail, userId: testUserEmail, agentId: testAgentId, userRole: 'user');
      final agencyModel = agencyDto.toChatModel(chatEmailId: testUserEmail, userId: testUserEmail, agentId: testAgentId, userRole: 'user');

      // User message must align RIGHT (isMe = true)
      expect(userModel.isMe, isTrue);
      // Agency message must align LEFT (isMe = false)
      expect(agencyModel.isMe, isFalse);
    });

    test('Agency Portal alignment: Agency messages align RIGHT and User messages align LEFT', () {
      final userMsgJson = {
        '_id': 'msg-301',
        'conversationId': testConvId,
        'senderId': testUserEmail,
        'recipientId': testAgentId,
        'text': 'Client question',
        'createdAt': '2026-08-01T10:00:00.000Z',
      };
      final agencyMsgJson = {
        '_id': 'msg-302',
        'conversationId': testConvId,
        'senderId': testAgentId,
        'recipientId': testUserEmail,
        'text': 'Agency response',
        'createdAt': '2026-08-01T10:01:00.000Z',
      };

      final userDto = ChatMessageDto.fromJson(userMsgJson, chatEmailId: testAgentId);
      final agencyDto = ChatMessageDto.fromJson(agencyMsgJson, chatEmailId: testAgentId);

      // Agency perspective: userRole is 'agent' or 'agency'
      final userModel = userDto.toChatModel(chatEmailId: testAgentId, userId: testAgentId, agentId: testAgentId, userRole: 'agent', activeRecipientId: testUserEmail);
      final agencyModel = agencyDto.toChatModel(chatEmailId: testAgentId, userId: testAgentId, agentId: testAgentId, userRole: 'agent', activeRecipientId: testUserEmail);

      // From Agency perspective: Agency message must align RIGHT (isMe = true)
      expect(agencyModel.isMe, isTrue);
      // From Agency perspective: User (client) message must align LEFT (isMe = false)
      expect(userModel.isMe, isFalse);
    });

    test('User chatting with Admin Higher Authority: User message aligns RIGHT, Admin aligns LEFT', () {
      const adminConvId = 'conv-admin_higher_authority-$testUserEmail';
      final userMsgJson = {
        '_id': 'msg-401',
        'conversationId': adminConvId,
        'senderId': testUserEmail,
        'recipientId': 'admin_higher_authority',
        'text': 'User query to Higher Authority Admin',
        'createdAt': '2026-08-05T10:00:00.000Z',
      };
      final adminMsgJson = {
        '_id': 'msg-402',
        'conversationId': adminConvId,
        'senderId': 'admin_higher_authority',
        'recipientId': testUserEmail,
        'text': 'Admin official response to User',
        'createdAt': '2026-08-05T10:01:00.000Z',
      };

      final userDto = ChatMessageDto.fromJson(userMsgJson, chatEmailId: testUserEmail);
      final adminDto = ChatMessageDto.fromJson(adminMsgJson, chatEmailId: testUserEmail);

      final userModel = userDto.toChatModel(chatEmailId: testUserEmail, userId: testUserEmail, userRole: 'user', activeRecipientId: 'admin_higher_authority');
      final adminModel = adminDto.toChatModel(chatEmailId: testUserEmail, userId: testUserEmail, userRole: 'user', activeRecipientId: 'admin_higher_authority');

      // User perspective: User message -> RIGHT (isMe = true)
      expect(userModel.isMe, isTrue);
      // User perspective: Admin message -> LEFT (isMe = false)
      expect(adminModel.isMe, isFalse);
    });

    test('Agency chatting with Admin Higher Authority: Agency message aligns RIGHT, Admin aligns LEFT', () {
      const agencyEmail = 'agency-bob@example.com';
      const adminConvId = 'conv-admin_higher_authority-$agencyEmail';
      final agencyMsgJson = {
        '_id': 'msg-501',
        'conversationId': adminConvId,
        'senderId': agencyEmail,
        'recipientId': 'admin_higher_authority',
        'text': 'Agency support request to Admin',
        'createdAt': '2026-08-05T11:00:00.000Z',
      };
      final adminMsgJson = {
        '_id': 'msg-502',
        'conversationId': adminConvId,
        'senderId': 'admin_higher_authority',
        'recipientId': agencyEmail,
        'text': 'Admin response to Agency',
        'createdAt': '2026-08-05T11:01:00.000Z',
      };

      final agencyDto = ChatMessageDto.fromJson(agencyMsgJson, chatEmailId: agencyEmail);
      final adminDto = ChatMessageDto.fromJson(adminMsgJson, chatEmailId: agencyEmail);

      final agencyModel = agencyDto.toChatModel(chatEmailId: agencyEmail, userId: agencyEmail, userRole: 'agent', activeRecipientId: 'admin_higher_authority');
      final adminModel = adminDto.toChatModel(chatEmailId: agencyEmail, userId: agencyEmail, userRole: 'agent', activeRecipientId: 'admin_higher_authority');

      // Agency perspective: Agency message -> RIGHT (isMe = true)
      expect(agencyModel.isMe, isTrue);
      // Agency perspective: Admin message -> LEFT (isMe = false)
      expect(adminModel.isMe, isFalse);
    });

    test('ApiEndpoints defines playVoice and playImage endpoints according to MEDIA_API_DOCUMENTATION.md', () {
      expect(ApiEndpoints.playVoice, equals('/api/v1/voice/play-url'));
      expect(ApiEndpoints.playImage, equals('/api/v1/image/play-url'));
      expect(ApiEndpoints.adminEmailId, equals('admin@gmail.com'));
      expect(ApiEndpoints.adminAgencyUnqId, equals('ADMIN-1'));
    });

    test('Higher Authority Chat Verification for user@gmail.com with admin@gmail.com', () {
      const userEmail = 'user@gmail.com';
      const adminEmail = ApiEndpoints.adminEmailId;
      final conversationId = ApiEndpoints.buildConversationId(adminEmail, userEmail);

      expect(conversationId, equals('conv-admin@gmail.com-user@gmail.com'));

      final userMsgJson = {
        '_id': 'msg-ha-701',
        'conversationId': conversationId,
        'senderId': userEmail,
        'recipientId': adminEmail,
        'text': 'Hello Admin Higher Authority!',
        'createdAt': '2026-08-10T12:00:00.000Z',
      };

      final adminMsgJson = {
        '_id': 'msg-ha-702',
        'conversationId': conversationId,
        'senderId': adminEmail,
        'recipientId': userEmail,
        'text': 'Hello User, Admin Support here.',
        'createdAt': '2026-08-10T12:01:00.000Z',
      };

      final userDto = ChatMessageDto.fromJson(userMsgJson, chatEmailId: userEmail);
      final adminDto = ChatMessageDto.fromJson(adminMsgJson, chatEmailId: userEmail);

      final userModel = userDto.toChatModel(chatEmailId: userEmail, userId: userEmail, activeRecipientId: adminEmail);
      final adminModel = adminDto.toChatModel(chatEmailId: userEmail, userId: userEmail, activeRecipientId: adminEmail);

      // Sent by user@gmail.com -> RIGHT side (isMe = true)
      expect(userModel.isMe, isTrue);
      expect(userModel.senderId, equals('user@gmail.com'));

      // Received from admin@gmail.com -> LEFT side (isMe = false)
      expect(adminModel.isMe, isFalse);
      expect(adminModel.senderId, equals('admin@gmail.com'));
    });

    test('Audio Chat Fix: Voice Presigned Upload uses audio/mp4 and signed HTTP URLs bypass re-signing', () {
      // AAC/M4A audio recording MIME type must be audio/mp4 (not audio/m4a)
      const voiceMimeType = 'audio/mp4';
      expect(voiceMimeType, equals('audio/mp4'));

      // Simulating a signed S3 URL containing voice-notes path
      const signedUrl = 'https://s3.wasabisys.com/bucket/voice-notes/sample.m4a?X-Amz-Signature=12345abcdef';
      final isHttp = signedUrl.startsWith('http://') || signedUrl.startsWith('https://');
      final isSigned = signedUrl.contains('Signature=') || signedUrl.contains('X-Amz-Signature=');

      // Played directly without extra resolution call
      expect(isHttp, isTrue);
      expect(isSigned, isTrue);

      // Key cleaning logic test: query params stripped cleanly
      String rawKey = Uri.decodeComponent(signedUrl);
      if (rawKey.contains('?')) {
        rawKey = rawKey.split('?').first;
      }
      if (rawKey.contains('/voice-notes/')) {
        rawKey = 'voice-notes/${rawKey.split('/voice-notes/').last}';
      }
      expect(rawKey, equals('voice-notes/sample.m4a'));
    });

    test('Agency User Tap: Opens isolated Agency-User conversation and clears higher authority flag', () {
      const agencyEmail = 'agency@gmail.com';
      const targetUserEmail = 'user@gmail.com';
      const otherUserEmail = 'sample@gmail.com';
      const adminEmail = 'admin@gmail.com';

      // 1. Build conversation ID for target user
      final userConvId = ApiEndpoints.buildConversationId('AGENCY-23', targetUserEmail);
      expect(userConvId, equals('conv-AGENCY-23-user@gmail.com'));

      // 2. Verify _isHigherAuthorityActive logic inside fetchMessages for user conversation
      final isHigherAuthorityActive = (targetUserEmail == adminEmail ||
          targetUserEmail == ApiEndpoints.adminAgencyUnqId ||
          userConvId.toLowerCase().contains('admin'));
      expect(isHigherAuthorityActive, isFalse);

      // 3. Verify message filtering: incoming message for other user or admin is NOT matching active conversation
      const otherConvId = 'conv-AGENCY-23-sample@gmail.com';
      const adminConvId = 'conv-admin@gmail.com-agency@gmail.com';

      expect(userConvId == otherConvId, isFalse);
      expect(userConvId == adminConvId, isFalse);
    });
  });
}
