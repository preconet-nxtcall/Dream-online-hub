import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/constants/storage_keys.dart';
import '../core/errors/exceptions.dart';
import '../models/chat/chat_message_model.dart';
import '../models/dto/chat/chat_message_dto.dart';
import '../network/chat_api_client.dart';
import '../storage/local_storage_repository.dart';
import '../storage/secure_storage_service.dart';
import '../utils/logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Abstract interface
// ─────────────────────────────────────────────────────────────────────────────

abstract class ChatRepository {
  /// Authenticate with the chat server using [emailId] and [password].
  /// Stores the chat JWT token in secure storage.
  Future<Map<String, dynamic>> loginToChat(String emailId, String password);

  /// Returns the chat JWT token stored from a previous [loginToChat].
  Future<String?> getChatToken();

  /// Fetch the conversation list for the currently authenticated user/agent.
  Future<List<Map<String, dynamic>>> fetchConversations();

  /// Fetch paginated message history for [conversationId].
  Future<List<ChatMessageModel>> fetchMessages(
    String conversationId, {
    String? recipientId,
    int limit = 50,
    String? cursor,
  });

  /// Get cached local messages for [conversationId] synchronously from storage.
  List<ChatMessageModel> getCachedMessages(String conversationId);

  /// Save local messages to Hive cache
  Future<void> saveLocalMessages(String conversationId, List<ChatMessageModel> messages);

  /// Returns the current user's emailId used on the chat server.
  Future<String?> getChatEmailId();

  /// Returns the agentId stored from chat login (e.g. AGENCY-23).
  Future<String?> getChatAgentId();

  /// Returns the user role stored from chat login (user, agent, admin).
  Future<String?> getChatUserRole();

  /// Request presigned upload URL for voice note (POST /api/v1/voice/presigned-url)
  Future<Map<String, dynamic>> getPresignedVoiceUrl(
      String conversationId, {String mimeType = 'audio/webm'});

  /// Request presigned upload URL for image (POST /api/v1/image/presigned-url)
  Future<Map<String, dynamic>> getPresignedImageUrl(
      String conversationId, {String mimeType = 'image/png'});

  /// Perform binary HTTP PUT upload to presigned uploadUrl
  Future<bool> uploadMediaFile(
    String uploadUrl,
    String filePath, {
    String mimeType = 'application/octet-stream',
    ProgressCallback? onProgress,
  });

  /// Retrieve dynamic signed playback URL for a voice note key (GET /api/v1/voice/play-url?key=...)
  Future<String?> getPlayVoiceUrl(String fileKey);

  /// Retrieve dynamic signed preview URL for an image key (GET /api/v1/image/play-url?key=...)
  Future<String?> getPlayImageUrl(String fileKey);
}

// ─────────────────────────────────────────────────────────────────────────────
// Implementation
// ─────────────────────────────────────────────────────────────────────────────

class ChatRepositoryImpl implements ChatRepository {
  final ChatApiClient _chatClient;
  final LocalStorageRepository _localStorage;
  final SecureStorageService _secureStorage;

  ChatRepositoryImpl({
    ChatApiClient? chatClient,
    LocalStorageRepository? localStorage,
    SecureStorageService? secureStorage,
  })  : _chatClient = chatClient ?? ChatApiClient.instance,
        _localStorage = localStorage ?? LocalStorageRepositoryImpl(),
        _secureStorage = secureStorage ?? SecureStorageService();

  // ── Auth ──────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> loginToChat(
      String emailId, String password) async {
    try {
      final response = await _chatClient.post(
        ApiEndpoints.chatLogin,
        data: {'emailId': emailId, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('error')) {
        throw ServerException(
          message: data['error']?.toString() ?? 'Chat login failed.',
          statusCode: 401,
        );
      }

      final token = data['token']?.toString() ?? '';
      final user = data['user'] as Map<String, dynamic>? ?? {};
      final chatEmailId =
          (user['emailId'] ?? user['_id'] ?? emailId).toString();
      final chatRole = (user['role'] ?? 'user').toString();
      String chatAgentId = (user['agentId'] ?? user['id'] ?? '').toString();
      if (chatAgentId.isEmpty || chatAgentId == chatEmailId) {
        final existingAgentId = await _secureStorage.read(StorageKeys.chatAgentId);
        if (existingAgentId != null && existingAgentId.isNotEmpty) {
          chatAgentId = existingAgentId;
        }
      }

      // Persist chat session (SecureStorage + LocalStorage fallback)
      await Future.wait([
        if (token.isNotEmpty) ...[
          _secureStorage.write(StorageKeys.chatToken, token),
          _localStorage.saveTokens(accessToken: token),
        ],
        _secureStorage.write(StorageKeys.chatEmailId, chatEmailId),
        if (chatAgentId.isNotEmpty)
          _secureStorage.write(StorageKeys.chatAgentId, chatAgentId),
        _secureStorage.write(StorageKeys.chatUserRole, chatRole),
      ]);

      AppLogger.info('[ChatRepo] Chat login success: $chatEmailId (role: $chatRole)');
      return data;
    } catch (e) {
      if (e is ServerException) rethrow;
      AppLogger.error('[ChatRepo] Chat login error: $e');
      throw ServerException(
        message: 'Unable to connect to chat server. Check if it is running.',
        statusCode: 503,
      );
    }
  }

  @override
  Future<String?> getChatToken() =>
      _secureStorage.read(StorageKeys.chatToken);

  @override
  Future<String?> getChatEmailId() =>
      _secureStorage.read(StorageKeys.chatEmailId);

  @override
  Future<String?> getChatAgentId() =>
      _secureStorage.read(StorageKeys.chatAgentId);

  @override
  Future<String?> getChatUserRole() =>
      _secureStorage.read(StorageKeys.chatUserRole);

  // ── Presigned Media Upload URLs ──────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getPresignedVoiceUrl(
      String conversationId, {String mimeType = 'audio/mp4'}) async {
    try {
      final response = await _chatClient.post(
        ApiEndpoints.presignedVoice,
        data: {'conversationId': conversationId, 'mimeType': mimeType},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('[ChatRepo] getPresignedVoiceUrl error: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getPresignedImageUrl(
      String conversationId, {String mimeType = 'image/png'}) async {
    try {
      final response = await _chatClient.post(
        ApiEndpoints.presignedImage,
        data: {'conversationId': conversationId, 'mimeType': mimeType},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('[ChatRepo] getPresignedImageUrl error: $e');
      return {};
    }
  }

  @override
  Future<bool> uploadMediaFile(
    String uploadUrl,
    String filePath, {
    String mimeType = 'application/octet-stream',
    ProgressCallback? onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        AppLogger.error('[ChatRepo] File does not exist at $filePath');
        return false;
      }

      final length = await file.length();
      AppLogger.info('[ChatRepo] Audio file size: $length bytes ($filePath)');

      // Fix: Ensure uploadUrl is absolute if a relative path was returned by mock presigned endpoint
      String fullUploadUrl = uploadUrl;
      if (!fullUploadUrl.startsWith('http://') && !fullUploadUrl.startsWith('https://')) {
        final baseUrl = ApiEndpoints.chatBaseUrl.endsWith('/')
            ? ApiEndpoints.chatBaseUrl.substring(0, ApiEndpoints.chatBaseUrl.length - 1)
            : ApiEndpoints.chatBaseUrl;
        final path = fullUploadUrl.startsWith('/') ? fullUploadUrl : '/$fullUploadUrl';
        fullUploadUrl = '$baseUrl$path';
      }

      AppLogger.info('[ChatRepo] Upload started: PUT $fullUploadUrl');

      final dio = Dio();
      final response = await dio.put(
        fullUploadUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'Content-Length': length,
          },
        ),
        onSendProgress: (sentBytes, totalBytes) {
          final total = totalBytes > 0 ? totalBytes : length;
          final pct = (sentBytes / total).clamp(0.0, 1.0);
          AppLogger.info('[ChatRepo] Uploaded bytes: $sentBytes / $total (${(pct * 100).toStringAsFixed(1)}%)');
          onProgress?.call(sentBytes, total);
        },
      );

      final success = response.statusCode == 200 || response.statusCode == 204;
      AppLogger.info('[ChatRepo] Upload completed. Status: ${response.statusCode}, Success: $success');
      return success;
    } catch (e) {
      AppLogger.error('[ChatRepo] uploadMediaFile error: $e');
      return false;
    }
  }

  @override
  Future<String?> getPlayVoiceUrl(String fileKey) async {
    try {
      String cleanKey = Uri.decodeComponent(fileKey);
      if (cleanKey.contains('?')) {
        cleanKey = cleanKey.split('?').first;
      }
      if (cleanKey.contains('/voice-notes/')) {
        cleanKey = 'voice-notes/${cleanKey.split('/voice-notes/').last}';
      } else if (cleanKey.contains('voice-notes/')) {
        cleanKey = 'voice-notes/${cleanKey.split('voice-notes/').last}';
      } else if (cleanKey.contains('key=')) {
        cleanKey = Uri.parse(cleanKey).queryParameters['key'] ?? cleanKey;
      }

      final response = await _chatClient.get(
        ApiEndpoints.playVoice,
        queryParameters: {'key': cleanKey},
      );
      final data = response.data as Map<String, dynamic>;
      final rawUrl = data['url']?.toString();
      if (rawUrl != null && rawUrl.isNotEmpty) {
        String resolvedUrl = rawUrl;
        if (!resolvedUrl.startsWith('http')) {
          final baseUrl = ApiEndpoints.chatBaseUrl.endsWith('/')
              ? ApiEndpoints.chatBaseUrl.substring(0, ApiEndpoints.chatBaseUrl.length - 1)
              : ApiEndpoints.chatBaseUrl;
          resolvedUrl = '$baseUrl$rawUrl';
        }
        try {
          final baseUri = Uri.parse(ApiEndpoints.chatBaseUrl);
          final urlUri = Uri.parse(resolvedUrl);
          if ((urlUri.host == 'localhost' || urlUri.host == '127.0.0.1') && baseUri.host.isNotEmpty && baseUri.host != 'localhost' && baseUri.host != '127.0.0.1') {
            resolvedUrl = urlUri.replace(host: baseUri.host, port: baseUri.hasPort ? baseUri.port : urlUri.port).toString();
          }
        } catch (_) {}
        return resolvedUrl;
      }
      return null;
    } catch (e) {
      AppLogger.error('[ChatRepo] getPlayVoiceUrl error: $e');
      return null;
    }
  }

  @override
  Future<String?> getPlayImageUrl(String fileKey) async {
    try {
      String cleanKey = Uri.decodeComponent(fileKey);
      if (cleanKey.contains('?')) {
        cleanKey = cleanKey.split('?').first;
      }
      if (cleanKey.contains('/images/')) {
        cleanKey = 'images/${cleanKey.split('/images/').last}';
      } else if (cleanKey.contains('images/')) {
        cleanKey = 'images/${cleanKey.split('images/').last}';
      } else if (cleanKey.contains('key=')) {
        cleanKey = Uri.parse(cleanKey).queryParameters['key'] ?? cleanKey;
      }

      final response = await _chatClient.get(
        ApiEndpoints.playImage,
        queryParameters: {'key': cleanKey},
      );
      final data = response.data as Map<String, dynamic>;
      final rawUrl = data['url']?.toString();
      if (rawUrl != null && rawUrl.isNotEmpty) {
        String resolvedUrl = rawUrl;
        if (!resolvedUrl.startsWith('http')) {
          final baseUrl = ApiEndpoints.chatBaseUrl.endsWith('/')
              ? ApiEndpoints.chatBaseUrl.substring(0, ApiEndpoints.chatBaseUrl.length - 1)
              : ApiEndpoints.chatBaseUrl;
          resolvedUrl = '$baseUrl$rawUrl';
        }
        try {
          final baseUri = Uri.parse(ApiEndpoints.chatBaseUrl);
          final urlUri = Uri.parse(resolvedUrl);
          if ((urlUri.host == 'localhost' || urlUri.host == '127.0.0.1') && baseUri.host.isNotEmpty && baseUri.host != 'localhost' && baseUri.host != '127.0.0.1') {
            resolvedUrl = urlUri.replace(host: baseUri.host, port: baseUri.hasPort ? baseUri.port : urlUri.port).toString();
          }
        } catch (_) {}
        return resolvedUrl;
      }
      return null;
    } catch (e) {
      AppLogger.error('[ChatRepo] getPlayImageUrl error: $e');
      return null;
    }
  }

  // ── Conversations ─────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> fetchConversations() async {
    try {
      final response =
          await _chatClient.get(ApiEndpoints.conversations);
      final data = response.data as Map<String, dynamic>;
      final list = data['conversations'] as List<dynamic>? ?? [];
      return list.map((c) => c as Map<String, dynamic>).toList();
    } catch (e) {
      AppLogger.warning('[ChatRepo] fetchConversations error: $e');
      return [];
    }
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  @override
  Future<List<ChatMessageModel>> fetchMessages(
    String conversationId, {
    String? recipientId,
    int limit = 50,
    String? cursor,
  }) async {
    final cachedUser = _localStorage.getUser();
    final storedEmail = await _secureStorage.read(StorageKeys.chatEmailId);
    final storedUserId = await _secureStorage.read(StorageKeys.userId);
    final storedAgentId = await _secureStorage.read(StorageKeys.chatAgentId);
    final storedRole = await _secureStorage.read(StorageKeys.chatUserRole) ??
        await _secureStorage.read(StorageKeys.userRole) ??
        cachedUser?.role ??
        'user';

    final myEmailId = (storedEmail != null && storedEmail.isNotEmpty)
        ? storedEmail
        : (cachedUser?.email ?? '');
    final myUserId = (storedUserId != null && storedUserId.isNotEmpty)
        ? storedUserId
        : (cachedUser?.id ?? '');
    final myAgentId = storedAgentId ?? '';
    final myRole = storedRole;

    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (cursor != null) queryParams['cursor'] = cursor;
      if (recipientId != null && recipientId.isNotEmpty) {
        queryParams['recipientId'] = recipientId;
        queryParams['userId'] = recipientId;
      }

      final response = await _chatClient.get(
        ApiEndpoints.conversationMessages(conversationId),
        queryParameters: queryParams,
      );

      if (response.statusCode == 404) {
        AppLogger.info('[ChatRepo] 404: New conversation $conversationId has no message history yet.');
        return getCachedMessages(conversationId);
      }

      final data = (response.data is Map<String, dynamic>)
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final rawList = data['messages'] as List<dynamic>? ?? [];
      final isAdminConversation = conversationId.startsWith(
          'conv-${ApiEndpoints.adminAgencyUnqId}-');
      bool isAdminId(String value) {
        final normalized = value.trim().toLowerCase();
        return normalized == ApiEndpoints.adminEmailId.toLowerCase() ||
            normalized == ApiEndpoints.adminAgencyUnqId.toLowerCase();
      }
      bool belongsToActiveConversation(Map<String, dynamic> map) {
        final messageConversationId =
            (map['conversationId'] ?? map['conversation_id'] ?? '').toString();
        if (messageConversationId.isNotEmpty &&
            messageConversationId != conversationId) {
          return false;
        }
        final dto = ChatMessageDto.fromJson(map, chatEmailId: myEmailId);
        if (isAdminConversation) {
          return isAdminId(dto.senderId) || isAdminId(dto.receiverId);
        }
        final target = (recipientId ?? '').trim().toLowerCase();
        if (target.isEmpty) return true;

        final sender = dto.senderId.trim().toLowerCase();
        final receiver = dto.receiverId.trim().toLowerCase();
        final myEmail = myEmailId.trim().toLowerCase();
        final myAgent = myAgentId.trim().toLowerCase();
        final myUser = myUserId.trim().toLowerCase();

        // 1. Explicit conversation ID match
        if (messageConversationId == conversationId) return true;

        // 2. Sender or receiver matches target recipient (selected user email / ID)
        if (sender == target || receiver == target) return true;

        // 3. Sender or receiver matches my agency credentials
        final isMyMessage = sender == myEmail || sender == myAgent || sender == myUser;
        return isMyMessage;
      }

      // Messages come back newest-first from the server; reverse for display
      final messages = rawList.reversed
          .whereType<Map<String, dynamic>>()
          .where(belongsToActiveConversation)
          .map((m) {
            return ChatMessageDto.fromJson(
              m,
              chatEmailId: myEmailId,
            ).toChatModel(
              chatEmailId: myEmailId,
              userId: myUserId,
              agentId: myAgentId,
              userRole: myRole,
              activeRecipientId: recipientId,
            );
          })
          .toList();

      // Cache locally
      if (messages.isNotEmpty) {
        await _localStorage.saveMessages(conversationId, messages);
      }
      AppLogger.info(
          '[ChatRepo] Loaded ${messages.length} messages for $conversationId');
      return messages;
    } catch (e) {
      AppLogger.warning(
          '[ChatRepo] fetchMessages error: $e — returning cached messages');
      return getCachedMessages(conversationId);
    }
  }

  @override
  List<ChatMessageModel> getCachedMessages(String conversationId) {
    if (conversationId.isEmpty) return [];
    final rawCached = _localStorage.getCachedMessages(conversationId);
    if (rawCached.isEmpty) return [];

    final isAdminConv = conversationId.startsWith(
        'conv-${ApiEndpoints.adminAgencyUnqId}-');
    bool isAdminId(String id) {
      final normalized = id.trim().toLowerCase();
      return normalized == ApiEndpoints.adminEmailId.toLowerCase() ||
          normalized == ApiEndpoints.adminAgencyUnqId.toLowerCase();
    }

    // Extract target user identifier if encoded in conversationId (e.g. conv-AGENCY-23-user@gmail.com)
    String targetUserInConvId = '';
    if (conversationId.startsWith('conv-')) {
      final parts = conversationId.split('-');
      if (parts.length >= 3) {
        targetUserInConvId = parts.sublist(2).join('-').trim().toLowerCase();
      }
    }

    final valid = rawCached.where((m) {
      final hasAdminParticipant =
          isAdminId(m.senderId) || isAdminId(m.receiverId);
      if (isAdminConv) {
        return hasAdminParticipant;
      } else {
        if (hasAdminParticipant) return false;
        if (targetUserInConvId.isNotEmpty) {
          final sender = m.senderId.trim().toLowerCase();
          final receiver = m.receiverId.trim().toLowerCase();
          return sender == targetUserInConvId || receiver == targetUserInConvId || m.isMe;
        }
        return true;
      }
    }).toList();
    if (valid.length != rawCached.length) {
      _localStorage.saveMessages(conversationId, valid);
    }
    return valid;
  }

  @override
  Future<void> saveLocalMessages(String conversationId, List<ChatMessageModel> messages) async {
    if (conversationId.isEmpty) return;
    await _localStorage.saveMessages(conversationId, messages);
  }
}
