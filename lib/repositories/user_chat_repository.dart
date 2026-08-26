import 'dart:async';
import '../models/chat/chat_message_model.dart';
import 'chat_repository.dart';

/// Specialized Chat Repository for USER APP
abstract class UserChatRepository extends ChatRepository {
  /// Fetches conversation history between logged-in user and assigned agency
  Future<List<ChatMessageModel>> fetchUserAgencyMessages(
    String agencyId,
    String userEmail, {
    int limit = 35,
  });
}

class UserChatRepositoryImpl extends ChatRepositoryImpl implements UserChatRepository {
  UserChatRepositoryImpl({
    super.chatClient,
    super.localStorage,
    super.secureStorage,
  });

  @override
  Future<List<ChatMessageModel>> fetchUserAgencyMessages(
    String agencyId,
    String userEmail, {
    int limit = 35,
  }) async {
    final convId = 'conv-$agencyId-$userEmail';
    return fetchMessages(convId, recipientId: agencyId, limit: limit);
  }
}
