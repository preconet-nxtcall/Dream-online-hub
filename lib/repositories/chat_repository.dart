import '../core/errors/exceptions.dart';
import '../models/chat/chat_message_model.dart';
import '../models/dto/chat/chat_message_dto.dart';
import '../models/dto/chat/send_message_request_dto.dart';
import '../network/api_client.dart';
import '../storage/local_storage_repository.dart';
import '../utils/logger.dart';

abstract class ChatRepository {
  Future<Map<String, dynamic>> fetchAssignedAgency();
  Future<List<ChatMessageModel>> fetchMessages(String userId);
  Future<ChatMessageModel> sendMessage({
    required String userId,
    required String message,
    String type = 'text',
    String? imageUrl,
    String? voiceDuration,
    String? replyToMessage,
  });
}

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient _apiClient;
  final LocalStorageRepository _localStorage;

  ChatRepositoryImpl({
    ApiClient? apiClient,
    LocalStorageRepository? localStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _localStorage = localStorage ?? LocalStorageRepositoryImpl();

  @override
  Future<Map<String, dynamic>> fetchAssignedAgency() async {
    try {
      final response = await _apiClient.get('/user/assigned-agency');
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
    } catch (_) {
      // Fallback assigned agency info
    }

    return {
      'id': 'agency_support_1',
      'name': 'Apex Premier Agency Support',
      'is_online': true,
      'is_ai_assistant': false,
      'avatar_url': null,
    };
  }

  @override
  Future<List<ChatMessageModel>> fetchMessages(String userId) async {
    try {
      final response = await _apiClient.get(
        '/chat/messages',
        queryParameters: {'receiver_id': userId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List dataList = response.data['messages'] ?? (response.data is List ? response.data : []);
        final messages = dataList
            .map((m) => ChatMessageDto.fromJson(m is Map<String, dynamic> ? m : {}).toDomainModel(currentUserId: 'me'))
            .toList();

        await _localStorage.saveMessages(userId, messages);
        return messages;
      }
    } on NetworkException catch (e) {
      AppLogger.warning('fetchMessages NetworkException: ${e.message}. Reading local cached history.');
    } catch (e) {
      AppLogger.warning('fetchMessages error: $e. Reading local cached history.');
    }

    final cached = _localStorage.getCachedMessages(userId);
    if (cached.isNotEmpty) {
      return cached;
    }

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (userId == 'admin_higher_authority') {
      final adminList = [
        ChatMessageModel(
          id: 'admin_1',
          senderId: 'admin_higher_authority',
          receiverId: 'me',
          message: 'Official System Administrator Channel. How can Higher Authority assist you?',
          timestamp: yesterday.subtract(const Duration(hours: 1)),
          isMe: false,
          status: 'seen',
        ),
        ChatMessageModel(
          id: 'admin_2',
          senderId: 'me',
          receiverId: 'admin_higher_authority',
          message: 'Connecting to system admin regarding agency escalation.',
          timestamp: now.subtract(const Duration(minutes: 15)),
          isMe: true,
          status: 'delivered',
        ),
      ];
      await _localStorage.saveMessages(userId, adminList);
      return adminList;
    }

    final defaultList = [
      // Yesterday Messages
      ChatMessageModel(
        id: '1',
        senderId: userId,
        receiverId: 'me',
        message: 'Welcome to your assigned Agency Support Portal! How can we assist your game market queries today?',
        timestamp: yesterday.subtract(const Duration(hours: 3)),
        isMe: false,
        status: 'seen',
      ),
      ChatMessageModel(
        id: '2',
        senderId: 'me',
        receiverId: userId,
        message: 'Hello! I wanted to check the daily withdrawal limit for Milan Morning market.',
        timestamp: yesterday.subtract(const Duration(hours: 2, minutes: 45)),
        isMe: true,
        status: 'seen',
      ),
      ChatMessageModel(
        id: '3',
        senderId: userId,
        receiverId: 'me',
        message: 'Here is the current daily withdrawal schedule and rates chart:',
        timestamp: yesterday.subtract(const Duration(hours: 2, minutes: 30)),
        isMe: false,
        type: 'text',
        status: 'seen',
      ),

      // Today Messages
      ChatMessageModel(
        id: '4',
        senderId: userId,
        receiverId: 'me',
        message: 'Audio voice note from assigned agency manager',
        timestamp: now.subtract(const Duration(minutes: 45)),
        isMe: false,
        type: 'voice',
        voiceDuration: '0:24',
        status: 'seen',
      ),
      ChatMessageModel(
        id: '5',
        senderId: 'me',
        receiverId: userId,
        message: 'Thank you for the quick voice response! Also placing a Kalyan Morning bid now.',
        timestamp: now.subtract(const Duration(minutes: 30)),
        isMe: true,
        type: 'reply',
        replyToMessage: 'Audio voice note from assigned agency manager',
        status: 'seen',
      ),
      ChatMessageModel(
        id: '6',
        senderId: userId,
        receiverId: 'me',
        message: 'Great! All Kalyan Morning market transactions are running live with instant auto payouts.',
        timestamp: now.subtract(const Duration(minutes: 10)),
        isMe: false,
        status: 'delivered',
      ),
    ];

    await _localStorage.saveMessages(userId, defaultList);
    return defaultList;
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String userId,
    required String message,
    String type = 'text',
    String? imageUrl,
    String? voiceDuration,
    String? replyToMessage,
  }) async {
    final requestDto = SendMessageRequestDto(
      receiverId: userId,
      message: message,
      type: type,
      imageUrl: imageUrl,
      voiceDuration: voiceDuration,
      replyToMessage: replyToMessage,
    );

    final now = DateTime.now();
    ChatMessageModel resultMsg;

    try {
      final response = await _apiClient.post(
        '/chat/send',
        data: requestDto.toJson(),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final Map<String, dynamic> dataMap = response.data['data'] ?? response.data;
        resultMsg = ChatMessageDto.fromJson(dataMap).toDomainModel(currentUserId: 'me');
      } else {
        resultMsg = ChatMessageModel(
          id: now.millisecondsSinceEpoch.toString(),
          senderId: 'me',
          receiverId: userId,
          message: message,
          timestamp: now,
          isMe: true,
          status: 'delivered',
          type: type,
          imageUrl: imageUrl,
          voiceDuration: voiceDuration,
          replyToMessage: replyToMessage,
        );
      }
    } catch (_) {
      resultMsg = ChatMessageModel(
        id: now.millisecondsSinceEpoch.toString(),
        senderId: 'me',
        receiverId: userId,
        message: message,
        timestamp: now,
        isMe: true,
        status: 'delivered',
        type: type,
        imageUrl: imageUrl,
        voiceDuration: voiceDuration,
        replyToMessage: replyToMessage,
      );
    }

    final existing = _localStorage.getCachedMessages(userId);
    existing.add(resultMsg);
    await _localStorage.saveMessages(userId, existing);

    return resultMsg;
  }
}
