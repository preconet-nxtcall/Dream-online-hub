import 'dart:async';
import '../models/chat/chat_message_model.dart';
import 'chat_repository.dart';

/// Specialized Chat Repository for AGENCY APP
abstract class AgencyChatRepository extends ChatRepository {
  /// Fetches conversation history between agency and an assigned client user
  Future<List<ChatMessageModel>> fetchAgencyClientMessages(
    String agencyId,
    String clientUserEmail, {
    int limit = 20,
  });
}

class AgencyChatRepositoryImpl extends ChatRepositoryImpl implements AgencyChatRepository {
  AgencyChatRepositoryImpl({
    super.chatClient,
    super.localStorage,
    super.secureStorage,
  });

  @override
  Future<List<ChatMessageModel>> fetchAgencyClientMessages(
    String agencyId,
    String clientUserEmail, {
    int limit = 20,
  }) async {
    final convId = 'conv-$agencyId-$clientUserEmail';
    return fetchMessages(convId, recipientId: clientUserEmail, limit: limit);
  }
}
