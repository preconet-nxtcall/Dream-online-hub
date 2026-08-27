import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import '../core/constants/api_endpoints.dart';
import '../models/chat/chat_message_model.dart';
import '../models/dto/chat/send_message_request_dto.dart';
import '../repositories/chat_repository.dart';
import '../socket/socket_events.dart';
import '../socket/socket_service.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_storage_repository.dart';
import '../storage/secure_storage_service.dart';
import '../utils/date_formatter.dart';
import '../utils/logger.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final SocketService _socketService;
  StreamSubscription<ChatMessageModel>? _messageSub;
  StreamSubscription<Map<String, bool>>? _typingSub;
  StreamSubscription<Map<String, dynamic>>? _messageSentSub;
  StreamSubscription<Map<String, dynamic>>? _messageQueuedSub;
  StreamSubscription<Map<String, dynamic>>? _messageStatusSub;
  // H3: Track all active upload-progress timers so they can be cancelled on dispose.
  final Map<String, Timer> _uploadTimers = {};
  String? _activeConversationId; // real conversationId from server
  String? _activeRecipientId;    // recipientId (emailId or agentId)
  // Incremented whenever the visible chat changes.  Responses from a previous
  // chat must never be allowed to replace the current chat's messages.
  int _conversationLoadEpoch = 0;
  String? _prevConversationId;   // saved before switching to Higher Authority
  String? _prevRecipientId;      // saved before switching to Higher Authority

  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isAgencyTyping = false;
  Timer? _typingTimeoutTimer;
  String? _errorMessage;
  List<Map<String, dynamic>> _conversations = [];
  ChatMessageModel? _replyingToMessage;
  bool _isHigherAuthorityActive = false;

  // Voice — no local state needed; recording is handled in the widget layer.
  // Image Staging state
  String? _stagedImagePath;
  String? _stagedImageCaption;

  ChatProvider({ChatRepository? chatRepository, SocketService? socketService})
      : _chatRepository = chatRepository ?? ChatRepositoryImpl(),
        _socketService = socketService ?? SocketService.instance {
    _messageSub = _socketService.messageStream.listen(_handleIncomingMessage);
    _typingSub = _socketService.typingStream.listen(_handleTypingEvent);
    // Subscribe to API-aligned status confirmation streams
    _messageSentSub =
        _socketService.messageSentStream.listen(_handleMessageSent);
    _messageQueuedSub =
        _socketService.messageQueuedStream.listen(_handleMessageQueued);
    _messageStatusSub =
        _socketService.messageStatusStream.listen(_handleMessageStatus);
  }

  /// Handles a fully-formed incoming message from `message:new`.
  /// Only `message:new` (and the legacy alias) is a full message payload.
  void _handleIncomingMessage(ChatMessageModel message) {
    if (_activeConversationId == null || _activeConversationId!.isEmpty) return;

    final recipientLower = (_activeRecipientId ?? '').trim().toLowerCase();
    final senderLower = message.senderId.trim().toLowerCase();
    final receiverLower = message.receiverId.trim().toLowerCase();

    final isAdminChat = recipientLower == ApiEndpoints.adminEmailId.toLowerCase() ||
        recipientLower == ApiEndpoints.adminAgencyUnqId.toLowerCase() ||
        _isHigherAuthorityActive;

    final conversationMatch = (message.id.isNotEmpty && _activeConversationId != null) &&
        (message.conversationId.trim().toLowerCase() == _activeConversationId!.trim().toLowerCase());

    final isRelevant = conversationMatch ||
        !message.isMe ||
        (recipientLower.isNotEmpty &&
            (senderLower == recipientLower ||
                receiverLower == recipientLower ||
                (isAdminChat &&
                    (senderLower == ApiEndpoints.adminEmailId.toLowerCase() ||
                        senderLower == ApiEndpoints.adminAgencyUnqId.toLowerCase() ||
                        receiverLower == ApiEndpoints.adminEmailId.toLowerCase() ||
                        receiverLower == ApiEndpoints.adminAgencyUnqId.toLowerCase()))));

    if (!isRelevant) return;
    AppLogger.info('💡 [ChatProvider] Incoming message event: ${message.toJson()}');
    addRealtimeMessage(message);

    // If an incoming message from the partner arrives while viewing the active chat,
    // auto-send read receipt immediately so sender gets Blue Ticks (seen status)
    if (!message.isMe && _activeConversationId != null && recipientLower.isNotEmpty) {
      _socketService.sendReadReceipt(
        _activeConversationId!,
        _activeRecipientId ?? '',
        messageIds: message.id.isNotEmpty ? [message.id] : null,
      );
    }
  }

  void _handleTypingEvent(Map<String, bool> typingMap) {
    final recipient = _activeRecipientId ?? '';
    if (recipient.isEmpty) return;

    final isTyping = typingMap[recipient] ?? false;
    if (_isAgencyTyping != isTyping) {
      _isAgencyTyping = isTyping;
      notifyListeners();
    }

    if (isTyping) {
      _typingTimeoutTimer?.cancel();
      _typingTimeoutTimer = Timer(const Duration(seconds: 3), () {
        _isAgencyTyping = false;
        notifyListeners();
      });
    } else {
      _typingTimeoutTimer?.cancel();
      _typingTimeoutTimer = null;
    }
  }

  /// `message:sent` — server confirmed the message was written to MongoDB.
  /// Payload: `{ _id, conversationId, status: 'sent', createdAt }`
  /// Find the oldest temp 'sending'/'queued' message and promote it.
  void _handleMessageSent(Map<String, dynamic> data) {
    final ackConversationId =
        (data['conversationId'] ?? data['conversation_id'] ?? '').toString();
    if (ackConversationId.isNotEmpty && ackConversationId != _activeConversationId) {
      return;
    }
    AppLogger.info('💡 [ChatProvider] message:sent ACK received: $data');
    final realId = (data['_id'] ?? data['id'] ?? data['messageId'] ?? '').toString();
    final createdAtStr = (data['createdAt'] ?? data['timestamp'] ?? '').toString();
    if (realId.isEmpty) {
      // If server ack didn't return an ID, still promote the oldest temp message to 'sent'
      final idx = _messages.lastIndexWhere(
        (m) => m.isMe && (m.status == 'sending' || m.status == 'queued'),
      );
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(status: 'sent', uploadProgress: 1.0);
        notifyListeners();
      }
      return;
    }

    // Don't process if we already have this message ID in the list
    if (_messages.any((m) => m.id == realId)) return;

    // Find the oldest unconfirmed temp message (sending or queued)
    final idx = _messages.lastIndexWhere(
      (m) => m.isMe && (m.status == 'sending' || m.status == 'queued'),
    );
    if (idx != -1) {
      final statusStr = (data['status'] ?? 'delivered').toString();
      final confirmed = _messages[idx].copyWith(
        id: realId,
        status: statusStr == 'queued' ? 'delivered' : statusStr,
        timestamp: createdAtStr.isNotEmpty
            ? DateFormatter.parseToLocal(createdAtStr)
            : _messages[idx].timestamp,
        uploadProgress: 1.0,
      );
      _messages[idx] = confirmed;
      if (_activeConversationId != null && _activeConversationId!.isNotEmpty) {
        _chatRepository.saveLocalMessages(_activeConversationId!, _messages);
      }
      notifyListeners();
    }
  }

  /// `message:queued` — immediate server ack that the message entered the Redis queue.
  /// Payload: `{ messageId, conversationId, status: 'queued', createdAt }`
  /// Update the most recent 'sending' temp message to 'queued'.
  void _handleMessageQueued(Map<String, dynamic> data) {
    final queuedConversationId =
        (data['conversationId'] ?? data['conversation_id'] ?? '').toString();
    if (queuedConversationId.isNotEmpty &&
        queuedConversationId != _activeConversationId) {
      return;
    }
    final idx = _messages.lastIndexWhere((m) => m.isMe && m.status == 'sending');
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(status: 'queued');
      notifyListeners();
    }
  }

  /// `message:delivered` / `message:read` relayed by server back to the sender.
  /// Updates the status of matching messages in the active conversation.
  void _handleMessageStatus(Map<String, dynamic> data) {
    final statusConversationId =
        (data['conversationId'] ?? data['conversation_id'] ?? '').toString();
    if (statusConversationId.isNotEmpty &&
        _activeConversationId != null &&
        statusConversationId.trim().toLowerCase() != _activeConversationId!.trim().toLowerCase()) {
      return;
    }
    final type = (data['type'] as String?) ?? '';

    if (type == 'delivered') {
      // Payload: { messageId, conversationId, deliveredAt }
      final messageId = (data['messageId'] ?? '').toString();
      if (messageId.isEmpty) return;
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx != -1 && _messages[idx].status != 'read') {
        _messages[idx] = _messages[idx].copyWith(status: 'delivered');
        notifyListeners();
      }
    } else if (type == 'read') {
      // Payload: { conversationId, readBy, messageIds, modifiedCount, readAt }
      final rawIds = data['messageIds'];
      final messageIds = rawIds is List
          ? rawIds.map((e) => e.toString()).toList()
          : <String>[];

      bool changed = false;
      if (messageIds.isNotEmpty) {
        for (final msgId in messageIds) {
          final idx = _messages.indexWhere((m) => m.id == msgId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(status: 'read');
            changed = true;
          }
        }
      } else {
        // No specific IDs — mark all my sent/delivered messages as read
        for (int i = 0; i < _messages.length; i++) {
          if (_messages[i].isMe && _messages[i].status != 'read') {
            _messages[i] = _messages[i].copyWith(status: 'read');
            changed = true;
          }
        }
      }
      if (changed) notifyListeners();
    }
  }

  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;
  bool _loadMoreError = false;

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isAgencyTyping => _isAgencyTyping;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get conversations => _conversations;
  String? get activeConversationId => _activeConversationId;
  ChatMessageModel? get replyingToMessage => _replyingToMessage;
  bool get isHigherAuthorityActive => _isHigherAuthorityActive;
  bool get hasMoreMessages => _hasMoreMessages;
  bool get isLoadingMore => _isLoadingMore;
  bool get loadMoreError => _loadMoreError;
  // isRecording is always false — recording is managed in VoiceRecorderWidget
  bool get isRecording => false;
  String? get stagedImagePath => _stagedImagePath;
  String? get stagedImageCaption => _stagedImageCaption;
  String? get activeRecipientId => _activeRecipientId;

  /// Clears the visible conversation before a new chat route resolves its
  /// recipient. This prevents the previous client/Admin messages appearing
  /// during asynchronous route initialization.
  void clearActiveConversation() {
    ++_conversationLoadEpoch;
    _activeConversationId = null;
    _activeRecipientId = null;
    _messages = [];
    _isLoading = false;
    _isLoadingMore = false;
    _loadMoreError = false;
    _isSending = false;
    _hasMoreMessages = true;
    _isAgencyTyping = false;
    _isHigherAuthorityActive = false;
    _prevConversationId = null;
    _prevRecipientId = null;
    _replyingToMessage = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Toggle or set state between agency and admin conversations.
  /// [defaultConversationId] is only used as a fallback when restoring agency chat.
  Future<void> setHigherAuthority(bool active, String defaultConversationId,
      {String? chatEmailId}) async {
    _isHigherAuthorityActive = active;
    if (_isHigherAuthorityActive) {
      // Save the current conversation so we can restore it later.
      _prevConversationId = _activeConversationId;
      _prevRecipientId = _activeRecipientId;

      final secureStorage = SecureStorageService();
      final currentUser = LocalStorageRepositoryImpl().getUser();
      final storedEmail = await secureStorage.read(StorageKeys.chatEmailId);
      final userEmail = (chatEmailId != null && chatEmailId.isNotEmpty)
          ? chatEmailId
          : ((storedEmail != null && storedEmail.isNotEmpty)
              ? storedEmail
              : (currentUser?.email ?? ''));

      if (currentUser != null && currentUser.isAgency) {
        // Agency chatting with Admin Higher Authority
        final storedAgentId = await secureStorage.read(StorageKeys.chatAgentId);
        final realAgencyId = (storedAgentId != null && storedAgentId.isNotEmpty)
            ? storedAgentId
            : (currentUser.id.startsWith('AGENCY') ? currentUser.id : 'AGENCY-${currentUser.id}');
        final adminConvId = ApiEndpoints.buildConversationId(
            ApiEndpoints.adminAgencyUnqId, realAgencyId);
        await fetchMessages(adminConvId,
            recipientId: ApiEndpoints.adminAgencyUnqId, limit: 35);
      } else {
        // User chatting with Admin Higher Authority (conv-ADMIN-1-userEmail)
        final adminConvId = ApiEndpoints.buildConversationId(
            ApiEndpoints.adminAgencyUnqId, userEmail);
        await fetchMessages(adminConvId,
            recipientId: ApiEndpoints.adminAgencyUnqId, limit: 35);
      }
    } else {
      // Restore previous agency conversation, or fall back to defaultConversationId.
      final restoreConvId = (_prevConversationId?.isNotEmpty == true)
          ? _prevConversationId!
          : defaultConversationId;
      final restoreRecipientId = (_prevRecipientId?.isNotEmpty == true)
          ? _prevRecipientId!
          : _activeRecipientId;
      _prevConversationId = null;
      _prevRecipientId = null;
      if (restoreConvId.isNotEmpty) {
        await fetchMessages(restoreConvId, recipientId: restoreRecipientId, limit: 35);
      } else {
        // C3: restoreConvId is empty — reset active IDs so the next outgoing
        // message is NOT routed to the old admin conversation.
        _activeConversationId = null;
        _activeRecipientId = null;
        _messages = [];
      }
    }
    notifyListeners();
  }

  /// Reset higher authority state to false synchronously
  void resetHigherAuthority() {
    _isHigherAuthorityActive = false;
    _prevConversationId = null;
    _prevRecipientId = null;
    notifyListeners();
  }

  Future<void> toggleHigherAuthority(String defaultConversationId,
      {String? chatEmailId}) async {
    await setHigherAuthority(!_isHigherAuthorityActive, defaultConversationId,
        chatEmailId: chatEmailId);
  }

  void setReplyingTo(ChatMessageModel? message) {
    _replyingToMessage = message;
    notifyListeners();
  }

  void cancelReply() {
    _replyingToMessage = null;
    notifyListeners();
  }

  // ── Real Voice Note Upload & Send ────────────────────────────────────────
  /// Called by the UI after the user records a voice note.
  /// [filePath] = local M4A file, [durationStr] = "mm:ss" string.
  Future<void> sendVoiceMessage(
    String userId,
    String filePath,
    String durationStr,
  ) async {
    // Build the temp bubble immediately so the user sees it right away
    await sendMessage(
      userId,
      '',
      type: 'voice',
      voiceDuration: durationStr,
      localVoicePath: filePath,
    );
  }

  // Image Staging Methods
  void setStagedImage(String path, {String? caption}) {
    _stagedImagePath = path;
    _stagedImageCaption = caption;
    notifyListeners();
  }

  void clearStagedImage() {
    _stagedImagePath = null;
    _stagedImageCaption = null;
    notifyListeners();
  }

  /// Auto fetch agency assigned to this user — kept for backward compat with existing screens.
  Future<Map<String, dynamic>> fetchAssignedAgency() async {
    // Return generic fallback — real agency info comes from conversations list.
    // Default to agency_support, NOT admin_higher_authority.
    return {
      'id': 'agency_support',
      'name': 'Agency Support',
      'is_online': true,
    };
  }

  /// Authenticate with the Node.js chat server.
  /// Called right after PHP login succeeds, using the user's email + password.
  Future<bool> loginToChat(String emailId, String password) async {
    try {
      await _chatRepository.loginToChat(emailId, password);
      // Connect socket with the new chat token
      await _socketService.connect();
      return true;
    } catch (e) {
      _errorMessage = 'Chat server connection failed. Messages may not be real-time.';
      notifyListeners();
      return false;
    }
  }

  /// Load all conversations for the current agent/user.
  Future<void> fetchConversations() async {
    try {
      _conversations = await _chatRepository.fetchConversations();
      notifyListeners();
    } catch (_) {}
  }

  /// Load initial messages for a conversation.
  /// Loads local Hive cache instantly so existing history renders without flickering,
  /// then merges fresh server messages seamlessly.
  Future<void> fetchMessages(String conversationId,
      {String? recipientId, int limit = 35}) async {
    if (conversationId.trim().isEmpty || recipientId?.trim().isEmpty != false) {
      _messages = [];
      _activeConversationId = null;
      _activeRecipientId = null;
      _errorMessage = 'Unable to open this conversation.';
      notifyListeners();
      return;
    }
    final loadEpoch = ++_conversationLoadEpoch;
    _activeConversationId = conversationId;
    _activeRecipientId = recipientId;

    // 1. Instantly load cached local messages from Hive synchronously
    final cached = _chatRepository.getCachedMessages(conversationId);
    if (cached.isNotEmpty) {
      _messages = cached;
      _isLoading = false;
    } else if (_messages.isEmpty) {
      _isLoading = true; // First time open with no cache — show smooth skeleton loading
    } else {
      _isLoading = false; // Keep existing memory messages visible while fetching in background
    }
    _isLoadingMore = false;
    _hasMoreMessages = true;
    _replyingToMessage = null;
    _errorMessage = null;
    _isHigherAuthorityActive = (recipientId == ApiEndpoints.adminEmailId ||
        recipientId == ApiEndpoints.adminAgencyUnqId);
    _safeNotify();

    final fetchStartTime = DateTime.now();

    try {
      final loaded = await _chatRepository.fetchMessages(
        conversationId,
        recipientId: recipientId,
        limit: limit,
      );

      // Smooth skeleton duration when loading for the first time
      if (_isLoading) {
        final elapsed = DateTime.now().difference(fetchStartTime).inMilliseconds;
        final remaining = 450 - elapsed;
        if (remaining > 0) {
          await Future.delayed(Duration(milliseconds: remaining));
        }
      }

      // A newer user/admin chat was opened while this request was in flight.
      if (loadEpoch != _conversationLoadEpoch ||
          _activeConversationId != conversationId ||
          _activeRecipientId != recipientId) {
        return;
      }

      final localMsgs = _messages.where((m) => m.isMe).toList();

      final mergedList = <ChatMessageModel>[...loaded];
      for (final local in localMsgs) {
        final exists = mergedList.any((m) => _isDuplicateMessage(local, m));
        if (!exists) {
          mergedList.add(local);
        }
      }
      mergedList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _messages = _deduplicateMessages(mergedList);

      await _chatRepository.saveLocalMessages(conversationId, _messages);
      _hasMoreMessages = loaded.length >= limit;
      _isLoading = false;
      
      // Emit read receipt with all unread message IDs from the other party
      if (recipientId != null && recipientId.isNotEmpty) {
        final unreadIds = _messages
            .where((m) => !m.isMe && m.status != 'read' && m.id.isNotEmpty)
            .map((m) => m.id)
            .toList();
        _socketService.sendReadReceipt(
          conversationId,
          recipientId,
          messageIds: unreadIds.isNotEmpty ? unreadIds : null,
        );
      }
    } catch (e) {
      if (loadEpoch != _conversationLoadEpoch) return;
      if (_messages.isEmpty) {
        _errorMessage = 'Failed to load conversation history.';
      }
    } finally {
      if (loadEpoch == _conversationLoadEpoch) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Load older messages (pagination) as user scrolls up
  Future<void> loadMoreMessages({int limit = 35}) async {
    if (_isLoadingMore || !_hasMoreMessages || _activeConversationId == null || _messages.isEmpty) {
      return;
    }

    final conversationId = _activeConversationId;
    final recipientId = _activeRecipientId;
    final loadEpoch = _conversationLoadEpoch;
    _isLoadingMore = true;
    _loadMoreError = false;
    notifyListeners();

    try {
      // API expects cursor as ISO date string of the oldest message, not its _id
      final oldestTimestamp = _messages.first.timestamp.toIso8601String();
      final olderMsgs = await _chatRepository.fetchMessages(
        conversationId!,
        recipientId: recipientId,
        limit: limit,
        cursor: oldestTimestamp,
      );

      if (loadEpoch != _conversationLoadEpoch ||
          _activeConversationId != conversationId ||
          _activeRecipientId != recipientId) {
        return;
      }

      if (olderMsgs.isEmpty) {
        _hasMoreMessages = false;
      } else {
        final newMsgs = olderMsgs.where((m) => !_messages.any((ex) => ex.id == m.id)).toList();
        if (newMsgs.isEmpty) {
          _hasMoreMessages = false;
        } else {
          _messages.insertAll(0, newMsgs);
          _hasMoreMessages = olderMsgs.length >= limit;
        }
      }
    } catch (e) {
      if (loadEpoch == _conversationLoadEpoch) {
        _loadMoreError = true;
      }
    } finally {
      if (loadEpoch == _conversationLoadEpoch) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<bool> sendMessage(
    String userId,
    String text, {
    String type = 'text',
    String? imageUrl,
    String? voiceDuration,
    String? localVoicePath,  // local file path for immediate playback
    bool isAgencyAdmin = false,
  }) async {
    final conversationId = _activeConversationId;
    final recipientId = _activeRecipientId;
    final safeRecipient = (recipientId ?? '').trim().toLowerCase();
    final safeUser = userId.trim().toLowerCase();

    final isRecipientMatch = (safeUser == safeRecipient) ||
        ((recipientId == ApiEndpoints.adminAgencyUnqId ||
                recipientId == ApiEndpoints.adminEmailId ||
                recipientId == 'admin_higher_authority') &&
            (userId == ApiEndpoints.adminAgencyUnqId ||
                userId == ApiEndpoints.adminEmailId ||
                userId == 'admin_higher_authority'));

    if (conversationId == null || conversationId.isEmpty ||
        recipientId == null || recipientId.isEmpty ||
        !isRecipientMatch) {
      return false;
    }
    final sendEpoch = _conversationLoadEpoch;
    final isVoice = type == 'voice' || type == 'audio' || voiceDuration != null;
    final isImage = type == 'image' || imageUrl != null || _stagedImagePath != null;
    final hasText = text.trim().isNotEmpty;
    // Guard: must have text, or image, or be a voice message
    if (!hasText && !isImage && !isVoice) {
      return false;
    }

    final effectiveLocalVoicePath = localVoicePath ?? (isVoice ? imageUrl : null);
    final finalImageUrl = isVoice ? null : (imageUrl ?? _stagedImagePath);
    final finalMessage = text.isNotEmpty
        ? text.trim()
        : (_stagedImageCaption ??
            (isVoice
                ? ''
                : (finalImageUrl != null
                    ? '📷 Image Attachment'
                    : '')));

    final String? replyText = _replyingToMessage?.message;
    final String actualType = _replyingToMessage != null ? 'reply' : (isVoice ? 'voice' : type);

    clearStagedImage();

    final isMedia = actualType == 'image' || actualType == 'voice' || isVoice || finalImageUrl != null || voiceDuration != null;
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();

    final tempMsg = ChatMessageModel(
      id: msgId,
      senderId: 'me',
      receiverId: recipientId,
      message: finalMessage,
      timestamp: DateTime.now(),
      isMe: true,
      status: isMedia ? 'uploading' : 'sending',
      type: actualType == 'reply' ? (finalImageUrl != null ? 'image' : (voiceDuration != null ? 'voice' : 'text')) : actualType,
      imageUrl: finalImageUrl,
      voiceDuration: voiceDuration,
      replyToMessage: replyText,
      fileSize: finalImageUrl != null ? '2.4 MB' : (voiceDuration != null ? '350 KB' : null),
      uploadProgress: isMedia ? 0.0 : null,
      isDownloaded: true,
      localFilePath: effectiveLocalVoicePath,  // store local path for immediate playback & S3 upload
    );

    _messages.add(tempMsg);
    final saveKeys = {
      conversationId,
    };
    for (final k in saveKeys) {
      _chatRepository.saveLocalMessages(k, _messages);
    }
    _isSending = true;
    _replyingToMessage = null;
    notifyListeners();

    try {
      final recipient = recipientId;

      // Construct SendMessageRequestDto matching backend API Documentation spec
      String msgType = 'text';
      String? imageKey;
      String? audioKey;
      int? audioDurationSec;

      if (tempMsg.type == 'voice' || isVoice || voiceDuration != null) {
        msgType = 'voice';
        if (voiceDuration != null && voiceDuration.contains(':')) {
          final parts = voiceDuration.split(':');
          audioDurationSec = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
        } else if (voiceDuration != null) {
          audioDurationSec = int.tryParse(voiceDuration) ?? 10;
        }

        // Step 1: Request presigned upload URL from REST API
        final presignedRes = await _chatRepository.getPresignedVoiceUrl(
          conversationId,
          mimeType: 'audio/mp4',
        );
        final uploadUrl = presignedRes['uploadUrl']?.toString();
        final fileKey = presignedRes['fileKey']?.toString();

        if (uploadUrl != null && effectiveLocalVoicePath != null) {
          // Step 2: Real binary HTTP PUT upload to Wasabi / S3 uploadUrl with onProgress
          final uploadSuccess = await _chatRepository.uploadMediaFile(
            uploadUrl,
            effectiveLocalVoicePath,
            mimeType: 'audio/mp4',
            onProgress: (sentBytes, totalBytes) {
              if (totalBytes > 0) {
                final pct = (sentBytes / totalBytes).clamp(0.0, 0.99);
                updateUploadProgress(msgId, pct);
              }
            },
          );

          if (!uploadSuccess) {
            final idx = _messages.indexWhere((m) => m.id == msgId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(status: 'failed', uploadProgress: null);
              for (final k in saveKeys) {
                _chatRepository.saveLocalMessages(k, _messages);
              }
              notifyListeners();
            }
            return false;
          }
          audioKey = fileKey;
          final idx = _messages.indexWhere((m) => m.id == msgId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              audioUrl: fileKey,
              uploadProgress: 1.0,
            );
            for (final k in saveKeys) {
              _chatRepository.saveLocalMessages(k, _messages);
            }
            notifyListeners();
          }
        } else {
          audioKey = fileKey ?? 'voice-${DateTime.now().millisecondsSinceEpoch}.m4a';
        }
      } else if (tempMsg.type == 'image' || finalImageUrl != null) {
        msgType = 'image';
        final rawPath = finalImageUrl ?? '';
        final isPng = rawPath.toLowerCase().endsWith('.png');

        // Step 1: Request presigned upload URL for image
        final presignedRes = await _chatRepository.getPresignedImageUrl(
          conversationId,
          mimeType: isPng ? 'image/png' : 'image/jpeg',
        );
        final uploadUrl = presignedRes['uploadUrl']?.toString();
        final fileKey = presignedRes['fileKey']?.toString();

        if (uploadUrl != null && rawPath.isNotEmpty && !rawPath.startsWith('http')) {
          // Step 2: Real binary HTTP PUT upload to Wasabi / S3 uploadUrl with onProgress
          final uploadSuccess = await _chatRepository.uploadMediaFile(
            uploadUrl,
            rawPath,
            mimeType: isPng ? 'image/png' : 'image/jpeg',
            onProgress: (sentBytes, totalBytes) {
              if (totalBytes > 0) {
                final pct = (sentBytes / totalBytes).clamp(0.0, 0.99);
                updateUploadProgress(msgId, pct);
              }
            },
          );

          if (!uploadSuccess) {
            final idx = _messages.indexWhere((m) => m.id == msgId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(status: 'failed', uploadProgress: null);
              for (final k in saveKeys) {
                _chatRepository.saveLocalMessages(k, _messages);
              }
              notifyListeners();
            }
            return false;
          }
          imageKey = fileKey;
        } else {
          imageKey = fileKey ?? (rawPath.contains('/') ? rawPath.split('/').last : rawPath);
        }
      }

      final effectiveRecipient = recipient;

      final requestDto = SendMessageRequestDto(
        conversationId: conversationId,
        recipientId: effectiveRecipient,
        type: msgType,
        text: msgType == 'text' ? finalMessage : null,
        imageKey: imageKey,
        audioKey: audioKey,
        audioDuration: audioDurationSec,
        replyToMessage: replyText,
      );

      // Ensure WebSocket connection is active before emitting message
      if (!_socketService.isConnected) {
        AppLogger.info('💡 [ChatProvider] WebSocket disconnected, reconnecting...');
        await _socketService.connect();
      }

      AppLogger.info('💡 [ChatProvider] Emitting message: ${requestDto.toJson()}');

      void onAck(dynamic res) {
        if (sendEpoch != _conversationLoadEpoch ||
            _activeConversationId != conversationId ||
            _activeRecipientId != recipientId) {
          return;
        }
        AppLogger.info('💡 [ChatProvider] Socket ACK callback received: $res');

        Map<String, dynamic> payload = {};
        if (res is Map<String, dynamic>) {
          payload = res;
        } else if (res is Map) {
          payload = Map<String, dynamic>.from(res);
        } else if (res is List) {
          for (final item in res) {
            if (item is Map<String, dynamic>) {
              payload = item;
              break;
            } else if (item is Map) {
              payload = Map<String, dynamic>.from(item);
              break;
            }
          }
        } else if (res != null) {
          payload = {'id': res.toString()};
        }

        _handleMessageSent(payload);
      }

      // Send via Socket.IO using real server event format with ACK callback
      _socketService.emit(SocketEvents.sendMessage, requestDto.toJson(), ack: onAck);

      // Fallback Timer: Ensure single tick (sent) appears within 1.0s even if server ACK is delayed
      Timer(const Duration(milliseconds: 1000), () {
        if (sendEpoch != _conversationLoadEpoch ||
            _activeConversationId != conversationId ||
            _activeRecipientId != recipientId) {
          return;
        }
        final idx = _messages.indexWhere((m) => m.id == msgId);
        if (idx != -1 && (_messages[idx].status == 'sending' || _messages[idx].status == 'queued' || _messages[idx].status == 'uploading')) {
          AppLogger.info('💡 [ChatProvider] Fallback timer promoting message $msgId to sent');
          _messages[idx] = _messages[idx].copyWith(status: 'sent', uploadProgress: null);
          for (final k in saveKeys) {
            _chatRepository.saveLocalMessages(k, _messages);
          }
          notifyListeners();
        }
      });

      final index = _messages.indexWhere((m) => m.id == msgId);
      if (index != -1) {
        for (final k in saveKeys) {
          _chatRepository.saveLocalMessages(k, _messages);
        }
      }

      return true;
    } catch (e) {
      // Mark the message as failed so the user can see and retry
      final index = _messages.indexWhere((m) => m.id == msgId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(status: 'failed', uploadProgress: null);
      }
      return false;
    } finally {
      if (sendEpoch == _conversationLoadEpoch) {
        _isSending = false;
        notifyListeners();
      }
    }
  }

  void updateUploadProgress(String messageId, double progress) {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(
        uploadProgress: progress.clamp(0.0, 0.99),
        status: 'uploading',
      );
      notifyListeners();
    }
  }

  Future<void> retryFailedMessage(String messageId) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final failedMsg = _messages[idx];
    _messages.removeAt(idx);
    notifyListeners();

    if (failedMsg.type == 'voice' && failedMsg.localFilePath != null) {
      await sendVoiceMessage(
        failedMsg.receiverId,
        failedMsg.localFilePath!,
        failedMsg.voiceDuration ?? '0:15',
      );
    } else if (failedMsg.imageUrl != null) {
      await sendMessage(
        failedMsg.receiverId,
        failedMsg.message,
        type: 'image',
        imageUrl: failedMsg.imageUrl,
      );
    } else {
      await sendMessage(
        failedMsg.receiverId,
        failedMsg.message,
        type: 'text',
      );
    }
  }

  void simulateMediaDownload(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    _messages[index] = _messages[index].copyWith(downloadProgress: 0.1, isDownloaded: false);
    notifyListeners();

    double progress = 0.1;
    // H3 (companion): Track download timers the same way as upload timers
    // so they are cancelled on dispose and cannot fire after provider is gone.
    final timerKey = 'dl-$messageId';
    _uploadTimers[timerKey]?.cancel();
    _uploadTimers[timerKey] = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      progress += 0.3;
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx == -1 || progress >= 1.0) {
        timer.cancel();
        _uploadTimers.remove(timerKey);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(downloadProgress: 1.0, isDownloaded: true);
          notifyListeners();
        }
      } else {
        _messages[idx] = _messages[idx].copyWith(downloadProgress: progress);
        notifyListeners();
      }
    });
  }

  void deleteMessage(String messageId) {
    _messages.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }

  bool _isDuplicateMessage(ChatMessageModel m1, ChatMessageModel m2) {
    if (m1.id.isNotEmpty && m1.id == m2.id) return true;
    final text1 = m1.message.trim();
    final text2 = m2.message.trim();
    if (m1.isMe == m2.isMe) {
      final timeDiff = m1.timestamp.difference(m2.timestamp).abs().inSeconds;
      if (timeDiff <= 120) {
        if (text1.isNotEmpty && text1 == text2) {
          return true;
        }
        if (m1.type == m2.type && (m1.type == 'image' || m1.type == 'voice')) {
          return true;
        }
      }
    }
    return false;
  }

  List<ChatMessageModel> _deduplicateMessages(List<ChatMessageModel> list) {
    final List<ChatMessageModel> result = [];
    for (final item in list) {
      final exists = result.any((existing) => _isDuplicateMessage(existing, item));
      if (!exists) {
        result.add(item);
      }
    }
    return result;
  }

  void addRealtimeMessage(ChatMessageModel message) {
    final exists = _messages.any((m) => _isDuplicateMessage(m, message));
    if (!exists) {
      _messages.add(message);
      _messages = _deduplicateMessages(_messages);
      if (_activeConversationId != null && _activeConversationId!.isNotEmpty) {
        _chatRepository.saveLocalMessages(_activeConversationId!, _messages);
      }
      notifyListeners();
    }
  }


  void _safeNotify() {
    final scheduler = WidgetsBinding.instance;
    if (scheduler.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      scheduler.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    } else {
      if (hasListeners) notifyListeners();
    }
  }

  @override
  void dispose() {
    _typingTimeoutTimer?.cancel();
    _messageSub?.cancel();
    _typingSub?.cancel();
    _messageSentSub?.cancel();
    _messageQueuedSub?.cancel();
    _messageStatusSub?.cancel();
    // H3: Cancel all in-flight upload progress timers to prevent
    // notifyListeners() being called after the provider is disposed.
    for (final timer in _uploadTimers.values) {
      timer.cancel();
    }
    _uploadTimers.clear();
    super.dispose();
  }
}
