enum SocketStatus { disconnected, connecting, connected, reconnecting, error }

class SocketState {
  final SocketStatus status;
  final int reconnectAttempts;
  final int pingLatencyMs;
  final DateTime? lastHeartbeatTime;
  final int queuedMessagesCount;
  final Set<String> onlineUserIds;
  final Map<String, bool> typingUsers;
  final Map<String, DateTime> userLastSeen;
  final String? errorMessage;

  const SocketState({
    this.status = SocketStatus.disconnected,
    this.reconnectAttempts = 0,
    this.pingLatencyMs = 0,
    this.lastHeartbeatTime,
    this.queuedMessagesCount = 0,
    this.onlineUserIds = const {},
    this.typingUsers = const {},
    this.userLastSeen = const {},
    this.errorMessage,
  });

  bool get isConnected => status == SocketStatus.connected;
  bool get isReconnecting => status == SocketStatus.reconnecting;

  SocketState copyWith({
    SocketStatus? status,
    int? reconnectAttempts,
    int? pingLatencyMs,
    DateTime? lastHeartbeatTime,
    int? queuedMessagesCount,
    Set<String>? onlineUserIds,
    Map<String, bool>? typingUsers,
    Map<String, DateTime>? userLastSeen,
    String? errorMessage,
  }) {
    return SocketState(
      status: status ?? this.status,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      pingLatencyMs: pingLatencyMs ?? this.pingLatencyMs,
      lastHeartbeatTime: lastHeartbeatTime ?? this.lastHeartbeatTime,
      queuedMessagesCount: queuedMessagesCount ?? this.queuedMessagesCount,
      onlineUserIds: onlineUserIds ?? this.onlineUserIds,
      typingUsers: typingUsers ?? this.typingUsers,
      userLastSeen: userLastSeen ?? this.userLastSeen,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
