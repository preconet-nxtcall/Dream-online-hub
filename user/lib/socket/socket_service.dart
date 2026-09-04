import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/api_endpoints.dart';
import '../core/constants/storage_keys.dart';
import '../models/chat/chat_message_model.dart';
import '../models/dto/chat/chat_message_dto.dart';
import '../models/dto/chat/send_message_request_dto.dart';
import '../storage/local_storage_repository.dart';
import '../storage/secure_storage_service.dart';
import '../utils/date_formatter.dart';
import '../utils/logger.dart';
import 'message_queue_service.dart';
import 'socket_events.dart';
import 'socket_state.dart';

class SocketService with WidgetsBindingObserver {
  static SocketService? _instance;
  static SocketService get instance => _instance ??= SocketService._internal();

  SocketService._internal({
    SecureStorageService? secureStorage,
    MessageQueueService? messageQueueService,
  })  : _secureStorage = secureStorage ?? SecureStorageService(),
        _messageQueue = messageQueueService ?? MessageQueueService() {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (e) {
      AppLogger.warning('SocketService WidgetsBinding observer warning: $e');
    }
  }

  factory SocketService({
    SecureStorageService? secureStorage,
    MessageQueueService? messageQueueService,
  }) {
    return SocketService._internal(
      secureStorage: secureStorage,
      messageQueueService: messageQueueService,
    );
  }

  final SecureStorageService _secureStorage;
  final MessageQueueService _messageQueue;

  io.Socket? _socket;
  SocketState _state = const SocketState();
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelayMs = 30000;
  static const int _initialReconnectDelayMs = 1000;

  // Stream Controllers for Reactive UI
  final _stateController = StreamController<SocketState>.broadcast();
  final _messageController = StreamController<ChatMessageModel>.broadcast();
  final _typingController = StreamController<Map<String, bool>>.broadcast();
  final _onlineUsersController = StreamController<Set<String>>.broadcast();

  // Stream Controllers for message status confirmations (API-aligned)
  // message:sent  → server confirmed write to DB (stub: { _id, status, createdAt })
  // message:queued → server queued the message (stub: { messageId, status, createdAt })
  // messageStatus  → server relayed delivered/read receipt back to sender
  final _messageSentController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageQueuedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters & Streams
  SocketState get state => _state;
  bool get isConnected => _socket?.connected ?? false;
  Stream<SocketState> get stateStream => _stateController.stream;
  Stream<ChatMessageModel> get messageStream => _messageController.stream;
  Stream<Map<String, bool>> get typingStream => _typingController.stream;
  Stream<Set<String>> get onlineUsersStream => _onlineUsersController.stream;

  /// Check if a specific user/client is currently online using normalized exact matching
  bool isUserOnline(String? targetId, {String? targetEmail}) {
    final onlineSet = _state.onlineUserIds;
    if (onlineSet.isEmpty) return false;

    final candidates = <String>{};
    void addCandidates(String? input) {
      if (input == null) return;
      final str = input.trim();
      if (str.isEmpty || str.startsWith('{')) return;
      final lower = str.toLowerCase();
      candidates.add(lower);

      if (lower.startsWith('agency-')) {
        final stripped = lower.substring(7);
        if (stripped.isNotEmpty) candidates.add(stripped);
      } else if (!lower.contains('@')) {
        candidates.add('agency-$lower');
      }

      if (lower.startsWith('conv-')) {
        final stripped = lower.substring(5);
        if (stripped.isNotEmpty) candidates.add(stripped);
      }

      if (lower.contains('@')) {
        final username = lower.split('@').first;
        if (username.length >= 3) {
          candidates.add(username);
        }
      }
    }

    addCandidates(targetId);
    addCandidates(targetEmail);

    if (candidates.isEmpty) return false;

    for (final rawOnline in onlineSet) {
      final online = rawOnline.trim().toLowerCase();
      if (online.isEmpty || online.startsWith('{')) continue;

      final onlineStrippedAgency = online.startsWith('agency-') ? online.substring(7) : online;
      final onlineStrippedConv = onlineStrippedAgency.startsWith('conv-') ? onlineStrippedAgency.substring(5) : onlineStrippedAgency;
      final onlineUsername = online.contains('@') ? online.split('@').first : online;

      for (final candidate in candidates) {
        if (online == candidate ||
            onlineStrippedAgency == candidate ||
            onlineStrippedConv == candidate ||
            (onlineUsername.length >= 3 && onlineUsername == candidate)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Get last seen DateTime for a specific user/client if available
  DateTime? getLastSeen(String? targetId, {String? targetEmail}) {
    final lastSeenMap = _state.userLastSeen;
    if (lastSeenMap.isEmpty) return null;

    final candidates = <String>{};
    void addCandidates(String? input) {
      if (input == null) return;
      final str = input.trim();
      if (str.isEmpty || str.startsWith('{')) return;
      final lower = str.toLowerCase();
      candidates.add(lower);

      if (lower.startsWith('agency-')) {
        final stripped = lower.substring(7);
        if (stripped.isNotEmpty) candidates.add(stripped);
      } else if (!lower.contains('@')) {
        candidates.add('agency-$lower');
      }

      if (lower.startsWith('conv-')) {
        final stripped = lower.substring(5);
        if (stripped.isNotEmpty) candidates.add(stripped);
      }

      if (lower.contains('@')) {
        final username = lower.split('@').first;
        if (username.length >= 3) {
          candidates.add(username);
        }
      }
    }

    addCandidates(targetId);
    addCandidates(targetEmail);

    if (candidates.isEmpty) return null;

    for (final entry in lastSeenMap.entries) {
      final key = entry.key.trim().toLowerCase();
      if (key.isEmpty || key.startsWith('{')) continue;

      final keyStrippedAgency = key.startsWith('agency-') ? key.substring(7) : key;
      final keyStrippedConv = keyStrippedAgency.startsWith('conv-') ? keyStrippedAgency.substring(5) : keyStrippedAgency;
      final keyUsername = key.contains('@') ? key.split('@').first : key;

      for (final candidate in candidates) {
        if (key == candidate ||
            keyStrippedAgency == candidate ||
            keyStrippedConv == candidate ||
            (keyUsername.length >= 3 && keyUsername == candidate)) {
          return entry.value;
        }
      }
    }
    return null;
  }

  /// Fired when server confirms a message was written to DB.
  /// Payload: `{ _id, conversationId, status: 'sent', createdAt }`
  Stream<Map<String, dynamic>> get messageSentStream =>
      _messageSentController.stream;

  /// Fired immediately when server queues the message.
  /// Payload: `{ messageId, conversationId, status: 'queued', createdAt }`
  Stream<Map<String, dynamic>> get messageQueuedStream =>
      _messageQueuedController.stream;

  /// Fired when server relays a delivered or read receipt back to the sender.
  /// Payload includes a `type` field: `'delivered'` or `'read'`.
  Stream<Map<String, dynamic>> get messageStatusStream =>
      _messageStatusController.stream;

  /// Connect to WebSocket server with JWT Token
  Future<void> connect({String? customToken, String? socketUrl}) async {
    if (_socket?.connected == true) return;

    // Reset reconnect counter on every explicit connect call to avoid exponential
    // backoff accumulating across sessions (e.g. foreground → background → foreground)
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();

    // Safely dispose existing socket if any before reconnecting
    if (_socket != null) {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    }

    _updateState(_state.copyWith(status: SocketStatus.connecting));
    final url = socketUrl ?? ApiEndpoints.chatSocketUrl;

    // Use chat JWT token (or PHP auth token as fallback)
    String? token = customToken;
    if (token == null || token.isEmpty) {
      try {
        token = await _secureStorage.read(StorageKeys.chatToken) ??
            await _secureStorage.read(StorageKeys.authToken);
      } catch (e) {
        AppLogger.warning('SecureStorage read error: $e');
      }
    }

    // Fallback to Hive local storage if secure storage read returned null
    if (token == null || token.isEmpty) {
      token = LocalStorageRepositoryImpl().getAccessToken();
    }

    // Fallback to backend B2B fixed API token so socket ALWAYS connects to backend on Render
    if (token == null || token.isEmpty) {
      AppLogger.info('Using B2B fixed token fallback to connect to Render socket backend.');
      token = ApiEndpoints.fixedToken;
    }

    try {
      final uri = Uri.parse(url);
      final cleanPath = uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path;
      final socketPath = cleanPath.isNotEmpty && cleanPath != '/'
          ? '$cleanPath/socket.io'
          : '/socket.io';

      _socket = io.io(
        url,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setPath(socketPath)
            .disableAutoConnect()
            .setAuth({'token': token})
            .enableReconnection()
            .build(),
      );

      _setupSocketListeners();
      _socket?.connect();
    } catch (e) {
      AppLogger.warning('Socket initialization bypassed: $e');
      _updateState(_state.copyWith(
        status: SocketStatus.disconnected,
        errorMessage: null,
      ));
    }
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      AppLogger.info('WebSocket Connected successfully!');
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();

      _updateState(_state.copyWith(
        status: SocketStatus.connected,
        reconnectAttempts: 0,
        errorMessage: null,
      ));

      _startHeartbeat();
      _requestOnlineUsers();

      // Flush offline message queue
      _messageQueue.flush((event, payload, onAck) {
        emit(event, payload, ack: onAck);
      });
      _updateState(_state.copyWith(queuedMessagesCount: _messageQueue.count));
    });

    _socket?.onDisconnect((reason) {
      AppLogger.warning('WebSocket Disconnected: $reason');
      _stopHeartbeat();
      _updateState(_state.copyWith(status: SocketStatus.disconnected));

      if (reason != 'io client disconnect') {
        _scheduleAutoRetry();
      }
    });

    _socket?.onConnectError((err) {
      AppLogger.error('WebSocket Connect Error: $err');
      _updateState(_state.copyWith(
        status: SocketStatus.error,
        errorMessage: err.toString(),
      ));
      _scheduleAutoRetry();
    });

    // ── message:new ──────────────────────────────────────────────────────────
    // Full incoming message delivered to the recipient's room.
    // Payload has senderId, text, type, etc. (full message object).
    void handleIncomingMessage(dynamic data) async {
      if (data is Map<String, dynamic>) {
        final cachedUser = LocalStorageRepositoryImpl().getUser();
        final chatEmailId =
            await _secureStorage.read(StorageKeys.chatEmailId) ?? cachedUser?.email ?? '';
        final userId =
            await _secureStorage.read(StorageKeys.userId) ?? cachedUser?.id ?? '';
        final agentId =
            await _secureStorage.read(StorageKeys.chatAgentId) ?? '';
        final userRole =
            await _secureStorage.read(StorageKeys.chatUserRole) ??
            await _secureStorage.read(StorageKeys.userRole) ??
            cachedUser?.role ??
            'user';

        final dto = ChatMessageDto.fromJson(data, chatEmailId: chatEmailId);
        final model = dto.toChatModel(
          chatEmailId: chatEmailId,
          userId: userId,
          agentId: agentId,
          userRole: userRole,
        );
        _messageController.add(model);

        // Auto-send delivery ack for messages incoming from another user
        if (!model.isMe && model.id.isNotEmpty && model.senderId.isNotEmpty) {
          final conversationId = (data['conversationId'] ?? '').toString();
          if (conversationId.isNotEmpty) {
            sendDeliveryAck(model.id, conversationId, model.senderId);
          }
        }
      }
    }

    // message:new  → real incoming message from recipient
    _socket?.on(SocketEvents.receiveMessage, handleIncomingMessage);
    // Legacy alias (some servers emit receive_message)
    _socket?.on(SocketEvents.receiveMessageLegacy, handleIncomingMessage);

    // ── message:sent ─────────────────────────────────────────────────────────
    // Server confirmation stub after Redis worker writes to MongoDB.
    // Payload: { _id, conversationId, status: 'sent', createdAt }
    void handleSentAck(dynamic data) {
      if (data is Map<String, dynamic>) {
        AppLogger.info('[Socket] message:sent ack — data=$data');
        _messageSentController.add(data);
      }
    }
    _socket?.on(SocketEvents.messageSent, handleSentAck);
    _socket?.on('message_sent', handleSentAck);
    _socket?.on('message_ack', handleSentAck);
    _socket?.on(SocketEvents.messageAck, handleSentAck);

    // ── message:queued ───────────────────────────────────────────────────────
    // Immediate ack from server that message:send was received and queued.
    // Payload: { status: 'queued', messageId, conversationId, createdAt }
    void handleQueuedAck(dynamic data) {
      if (data is Map<String, dynamic>) {
        AppLogger.info('[Socket] message:queued ack — data=$data');
        _messageQueuedController.add(data);
      }
    }
    _socket?.on(SocketEvents.messageQueued, handleQueuedAck);
    _socket?.on('message_queued', handleQueuedAck);

    // ── message:delivered (server → client relay) ─────────────────────────────
    // Server relays to the original sender when the recipient confirms delivery.
    // Payload: { messageId, conversationId, deliveredAt }
    _socket?.on(SocketEvents.messageDelivered, (data) {
      if (data is Map<String, dynamic>) {
        _messageStatusController.add({'type': 'delivered', ...data});
      }
    });

    // ── message:read (server → client relay) ──────────────────────────────────
    // Server relays to the original sender when the recipient marks messages read.
    // Payload: { conversationId, readBy, messageIds, modifiedCount, readAt }
    _socket?.on(SocketEvents.messageRead, (data) {
      if (data is Map<String, dynamic>) {
        _messageStatusController.add({'type': 'read', ...data});
      }
    });

    // Heartbeat Pong Handler
    _socket?.on(SocketEvents.pong, (data) {
      final now = DateTime.now();
      int latency = 0;
      if (data is Map<String, dynamic> && data['timestamp'] != null) {
        final sentTime = data['timestamp'] as int;
        latency = now.millisecondsSinceEpoch - sentTime;
      }
      _updateState(_state.copyWith(
        pingLatencyMs: latency,
        lastHeartbeatTime: now,
      ));
    });

    // Presence & Online Status Handlers (presence:res, presence_res, etc.)
    void handlePresenceRes(dynamic data) {
      if (data is Map) {
        final String userId = (data['emailId'] ?? data['userId'] ?? data['user_id'] ?? data['_id'] ?? data['id'] ?? '').toString().trim();
        final bool isOnline = data['isOnline'] ?? data['is_online'] ?? data['online'] ?? false;
        if (userId.isNotEmpty && !userId.startsWith('{')) {
          final updatedSet = Set<String>.from(_state.onlineUserIds);
          final updatedLastSeen = Map<String, DateTime>.from(_state.userLastSeen);
          if (isOnline) {
            updatedSet.add(userId);
          } else {
            final target = userId.toLowerCase();
            final targetStripped = target.replaceAll('agency-', '').replaceAll('conv-', '');
            updatedSet.removeWhere((id) {
              final itemLower = id.toLowerCase();
              final itemStripped = itemLower.replaceAll('agency-', '').replaceAll('conv-', '');
              return itemLower == target ||
                     itemStripped == targetStripped ||
                     (itemLower.contains('@') && itemLower.split('@').first == target) ||
                     (target.contains('@') && target.split('@').first == itemLower);
            });
            final bool wasOnline = isUserOnline(userId);
            dynamic rawTime = data['lastSeen'] ?? data['last_seen'] ?? data['timestamp'] ?? data['updatedAt'];
            if (rawTime != null) {
              final parsed = DateFormatter.parseToLocal(rawTime);
              if (parsed != null) updatedLastSeen[userId] = parsed;
            } else if (wasOnline) {
              updatedLastSeen[userId] = DateTime.now();
            }
          }
          _updateState(_state.copyWith(onlineUserIds: updatedSet, userLastSeen: updatedLastSeen));
          _onlineUsersController.add(updatedSet);
        }
      }
    }

    void handleOnlineUsersList(dynamic data) {
      final ids = <String>{};
      void extractIds(dynamic item) {
        if (item is Map) {
          final id = (item['userId'] ?? item['user_id'] ?? item['email'] ?? item['emailId'] ?? item['_id'] ?? item['id'])?.toString();
          if (id != null && id.isNotEmpty && !id.startsWith('{')) ids.add(id);
        } else if (item is String) {
          final id = item.trim();
          if (id.isNotEmpty && !id.startsWith('{')) ids.add(id);
        } else if (item != null) {
          final id = item.toString().trim();
          if (id.isNotEmpty && !id.startsWith('{')) ids.add(id);
        }
      }

      if (data is List) {
        for (final item in data) {
          extractIds(item);
        }
      } else if (data is Map) {
        final users = data['users'] ?? data['onlineUsers'] ?? data['data'] ?? data['online_users'];
        if (users is List) {
          for (final item in users) {
            extractIds(item);
          }
        } else {
          extractIds(data);
        }
      }
      _updateState(_state.copyWith(onlineUserIds: ids));
      _onlineUsersController.add(ids);
    }

    void handleUserOnline(dynamic data) {
      String? userId;
      if (data is Map) {
        userId = (data['userId'] ?? data['user_id'] ?? data['email'] ?? data['emailId'] ?? data['_id'] ?? data['id'])?.toString();
      } else if (data != null) {
        userId = data.toString().trim();
      }
      if (userId != null && userId.isNotEmpty && !userId.startsWith('{')) {
        final updatedSet = Set<String>.from(_state.onlineUserIds)..add(userId);
        _updateState(_state.copyWith(onlineUserIds: updatedSet));
        _onlineUsersController.add(updatedSet);
      }
    }

    void handleUserOffline(dynamic data) {
      String? userId;
      if (data is Map) {
        userId = (data['userId'] ?? data['user_id'] ?? data['email'] ?? data['emailId'] ?? data['_id'] ?? data['id'])?.toString();
      } else if (data != null) {
        userId = data.toString().trim();
      }
      if (userId != null && userId.isNotEmpty && !userId.startsWith('{')) {
        final target = userId.toLowerCase();
        final targetStripped = target.replaceAll('agency-', '').replaceAll('conv-', '');
        final updatedSet = Set<String>.from(_state.onlineUserIds);
        final updatedLastSeen = Map<String, DateTime>.from(_state.userLastSeen);
        updatedSet.removeWhere((id) {
          final itemLower = id.toLowerCase();
          final itemStripped = itemLower.replaceAll('agency-', '').replaceAll('conv-', '');
          return itemLower == target ||
                 itemStripped == targetStripped ||
                 (itemLower.contains('@') && itemLower.split('@').first == target) ||
                 (target.contains('@') && target.split('@').first == itemLower);
        });
        final bool wasOnline = isUserOnline(userId);
        dynamic rawTime = (data is Map) ? (data['lastSeen'] ?? data['last_seen'] ?? data['timestamp'] ?? data['updatedAt']) : null;
        if (rawTime != null) {
          final parsed = DateFormatter.parseToLocal(rawTime);
          if (parsed != null) updatedLastSeen[userId] = parsed;
        } else if (wasOnline) {
          updatedLastSeen[userId] = DateTime.now();
        }
        _updateState(_state.copyWith(onlineUserIds: updatedSet, userLastSeen: updatedLastSeen));
        _onlineUsersController.add(updatedSet);
      }
    }

    _socket?.on(SocketEvents.presenceRes, handlePresenceRes);
    _socket?.on('presence_res', handlePresenceRes);
    _socket?.on('presence:response', handlePresenceRes);

    _socket?.on(SocketEvents.onlineUsersList, handleOnlineUsersList);
    _socket?.on('users:online', handleOnlineUsersList);
    _socket?.on('users_online', handleOnlineUsersList);
    _socket?.on('online_users', handleOnlineUsersList);
    _socket?.on('get_online_users_res', handleOnlineUsersList);

    _socket?.on(SocketEvents.userOnline, handleUserOnline);
    _socket?.on('user:online', handleUserOnline);

    _socket?.on(SocketEvents.userOffline, handleUserOffline);
    _socket?.on('user:offline', handleUserOffline);

    // Typing Indicators Handler
    _socket?.on(SocketEvents.userTyping, (data) {
      if (data is Map<String, dynamic>) {
        final String userId = (data['user_id'] ?? data['userId'] ?? '').toString();
        final bool isTyping = data['is_typing'] ?? data['isTyping'] ?? false;
        if (userId.isNotEmpty) {
          final updatedTyping = Map<String, bool>.from(_state.typingUsers);
          updatedTyping[userId] = isTyping;
          _updateState(_state.copyWith(typingUsers: updatedTyping));
          _typingController.add(updatedTyping);
        }
      }
    });
  }

  /// Heartbeat Ping Timer (every 25 seconds)
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (isConnected) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _socket?.emit(SocketEvents.ping, {'timestamp': timestamp});
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Exponential Backoff Auto-Retry Reconnection
  void _scheduleAutoRetry({String? socketUrl, String? token}) {
    _reconnectTimer?.cancel();

    // Limit reconnect attempts on localhost to avoid infinite log warnings when Socket.IO is offline
    if (_reconnectAttempts >= 3 && ApiEndpoints.baseUrl.contains('localhost')) {
      AppLogger.info('WebSocket auto-retry paused on Localhost after 3 attempts.');
      _updateState(_state.copyWith(status: SocketStatus.disconnected));
      return;
    }

    _reconnectAttempts++;

    // Calculate delay: 1s, 2s, 4s, 8s, 16s... up to 30s
    final delayMs = (_initialReconnectDelayMs * (1 << (_reconnectAttempts - 1)))
        .clamp(1000, _maxReconnectDelayMs);

    AppLogger.warning('Scheduling socket reconnect attempt #$_reconnectAttempts in ${delayMs}ms...');
    _updateState(_state.copyWith(
      status: SocketStatus.reconnecting,
      reconnectAttempts: _reconnectAttempts,
    ));

    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      connect(customToken: token, socketUrl: socketUrl);
    });
  }

  /// Emit event to Socket with optional offline Queueing
  void emit(String event, dynamic payload, {Function(dynamic response)? ack}) {
    if (isConnected) {
      if (ack != null) {
        _socket?.emitWithAck(event, payload, ack: ack);
      } else {
        _socket?.emit(event, payload);
      }
    } else {
      // Only queue persistent chat events (messages, delivery acks, read receipts)
      // Ignore transient UI events like typing_start, typing_stop, presence:check
      if (event == SocketEvents.sendMessage ||
          event == SocketEvents.messageDelivered ||
          event == SocketEvents.messageRead) {
        AppLogger.warning('Socket disconnected. Queueing event [$event] for background retry.');
        _messageQueue.enqueue(event: event, payload: payload, onAck: ack);
        _updateState(_state.copyWith(queuedMessagesCount: _messageQueue.count));
      }
    }
  }

  /// High-level Real-Time Chat Message Sender
  void sendChatMessage({
    required String conversationId,
    required String receiverId,
    required String message,
    String type = 'text',
    String? imageUrl,
    String? voiceDuration,
    String? replyToMessage,
  }) {
    final payload = SendMessageRequestDto(
      conversationId: conversationId,
      recipientId: receiverId,
      text: message,
      type: type,
      imageKey: imageUrl,
      audioKey: voiceDuration,
      replyToMessage: replyToMessage,
    ).toJson();

    emit(SocketEvents.sendMessage, payload);
  }

  Timer? _typingDebounceTimer;

  /// Real-Time Typing Actions with 400ms Debouncer
  /// Emits typing:start immediately, then resets the stop timer on each call.
  void sendTypingStart(String receiverId) {
    // Emit typing start immediately on each keystroke call
    // Send both snake_case and camelCase keys for maximum backend compatibility
    emit(SocketEvents.typingStart, {'receiver_id': receiverId, 'receiverId': receiverId});

    // Restart the auto-stop debounce timer
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
      sendTypingStop(receiverId);
    });
  }

  void sendTypingStop(String receiverId) {
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = null;
    emit(SocketEvents.typingStop, {'receiver_id': receiverId, 'receiverId': receiverId});
  }

  /// Send Message Delivered Acknowledgment (message:delivered)
  void sendDeliveryAck(String messageId, String conversationId, String senderId) {
    emit(SocketEvents.messageDelivered, {
      'messageId': messageId,
      'conversationId': conversationId,
      'senderId': senderId,
    });
  }

  /// Send Message Read Receipt (message:read)
  void sendReadReceipt(String conversationId, String senderId, {List<String>? messageIds}) {
    emit(SocketEvents.messageRead, {
      'conversationId': conversationId,
      'senderId': senderId,
      if (messageIds != null && messageIds.isNotEmpty) 'messageIds': messageIds,
    });
  }

  /// Check User Presence Online Status (presence:check)
  void checkUserPresence(String emailId) {
    if (emailId.isNotEmpty) {
      final payload = {'userId': emailId, 'emailId': emailId, 'user_id': emailId};
      emit(SocketEvents.presenceCheck, payload);
      emit('presence_check', payload);
      emit('check_presence', payload);
      emit('user:presence', payload);
    }
  }

  /// Request Online Users List
  void _requestOnlineUsers() {
    emit(SocketEvents.getOnlineUsers, {});
    emit('get_online_users', {});
    emit('users:online', {});
    emit('getOnlineUsers', {});
    emit('online_users', {});
  }

  /// App Lifecycle Observer: Handles Background Reconnects
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      AppLogger.info('App Resumed: Verifying WebSocket connection status...');
      if (!isConnected) {
        connect();
      }
    } else if (lifecycleState == AppLifecycleState.paused) {
      AppLogger.info('App Paused: Throttling background heartbeat...');
    }
  }

  void _updateState(SocketState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Disconnect socket connection
  void disconnect() {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _updateState(const SocketState());
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = null;
    disconnect();
    _stateController.close();
    _messageController.close();
    _typingController.close();
    _onlineUsersController.close();
    _messageSentController.close();
    _messageQueuedController.close();
    _messageStatusController.close();
  }
}
