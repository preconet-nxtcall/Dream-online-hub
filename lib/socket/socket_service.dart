import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants/api_endpoints.dart';
import '../core/constants/storage_keys.dart';
import '../models/chat/chat_message_model.dart';
import '../models/dto/chat/chat_message_dto.dart';
import '../models/dto/chat/send_message_request_dto.dart';
import '../storage/secure_storage_service.dart';
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

  // Getters & Exponents
  SocketState get state => _state;
  bool get isConnected => _socket?.connected ?? false;
  Stream<SocketState> get stateStream => _stateController.stream;
  Stream<ChatMessageModel> get messageStream => _messageController.stream;
  Stream<Map<String, bool>> get typingStream => _typingController.stream;
  Stream<Set<String>> get onlineUsersStream => _onlineUsersController.stream;

  /// Connect to WebSocket server with JWT Token
  Future<void> connect({String? customToken, String? socketUrl}) async {
    if (_socket?.connected == true) return;

    // Safely dispose existing socket if any before reconnecting
    if (_socket != null) {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    }

    _updateState(_state.copyWith(status: SocketStatus.connecting));
    final token = customToken ?? await _secureStorage.read(StorageKeys.authToken);
    final url = socketUrl ?? ApiEndpoints.socketUrl;

    try {
      _socket = io.io(
        url,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token ?? ''})
            .enableReconnection()
            .build(),
      );

      _setupSocketListeners();
      _socket?.connect();
    } catch (e) {
      AppLogger.error('Socket initialization error: $e');
      _updateState(_state.copyWith(
        status: SocketStatus.error,
        errorMessage: 'Failed to initialize socket connection.',
      ));
      _scheduleAutoRetry(socketUrl: socketUrl, token: token);
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

    // Real-Time Chat Message Handler
    _socket?.on(SocketEvents.receiveMessage, (data) {
      if (data is Map<String, dynamic>) {
        final dto = ChatMessageDto.fromJson(data);
        final model = dto.toDomainModel(currentUserId: 'me');
        _messageController.add(model);
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

    // Online Status Presence Handler
    _socket?.on(SocketEvents.onlineUsersList, (data) {
      if (data is List) {
        final ids = data.map((e) => e.toString()).toSet();
        _updateState(_state.copyWith(onlineUserIds: ids));
        _onlineUsersController.add(ids);
      }
    });

    _socket?.on(SocketEvents.userOnline, (data) {
      final userId = data?.toString();
      if (userId != null && userId.isNotEmpty) {
        final updatedSet = Set<String>.from(_state.onlineUserIds)..add(userId);
        _updateState(_state.copyWith(onlineUserIds: updatedSet));
        _onlineUsersController.add(updatedSet);
      }
    });

    _socket?.on(SocketEvents.userOffline, (data) {
      final userId = data?.toString();
      if (userId != null && userId.isNotEmpty) {
        final updatedSet = Set<String>.from(_state.onlineUserIds)..remove(userId);
        _updateState(_state.copyWith(onlineUserIds: updatedSet));
        _onlineUsersController.add(updatedSet);
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
      AppLogger.warning('Socket disconnected. Queueing event [$event] for background retry.');
      _messageQueue.enqueue(event: event, payload: payload, onAck: ack);
      _updateState(_state.copyWith(queuedMessagesCount: _messageQueue.count));
    }
  }

  /// High-level Real-Time Chat Message Sender
  void sendChatMessage({
    required String receiverId,
    required String message,
    String type = 'text',
    String? imageUrl,
    String? voiceDuration,
    String? replyToMessage,
  }) {
    final payload = SendMessageRequestDto(
      receiverId: receiverId,
      message: message,
      type: type,
      imageUrl: imageUrl,
      voiceDuration: voiceDuration,
      replyToMessage: replyToMessage,
    ).toJson();

    emit(SocketEvents.sendMessage, payload);
  }

  Timer? _typingDebounceTimer;

  /// Real-Time Typing Actions with 400ms Debouncer
  void sendTypingStart(String receiverId) {
    if (_typingDebounceTimer?.isActive ?? false) {
      _typingDebounceTimer?.cancel();
    } else {
      emit(SocketEvents.typingStart, {'receiver_id': receiverId});
    }

    _typingDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
      sendTypingStop(receiverId);
    });
  }

  void sendTypingStop(String receiverId) {
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = null;
    emit(SocketEvents.typingStop, {'receiver_id': receiverId});
  }

  /// Request Online Users List
  void _requestOnlineUsers() {
    emit(SocketEvents.getOnlineUsers, {});
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
    disconnect();
    _stateController.close();
    _messageController.close();
    _typingController.close();
    _onlineUsersController.close();
  }
}
