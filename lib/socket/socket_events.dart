class SocketEvents {
  // Connection & Lifecycle Events
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String connectError = 'connect_error';
  static const String reconnect = 'reconnect';
  static const String reconnecting = 'reconnecting';
  static const String ping = 'ping';
  static const String pong = 'pong';

  // Real-Time Chat Messaging Events
  static const String sendMessage = 'send_message';
  static const String receiveMessage = 'receive_message';
  static const String messageAck = 'message_ack';
  static const String messageDelivered = 'message_delivered';
  static const String messageRead = 'message_read';

  // Presence / Online Status Events
  static const String userOnline = 'user_online';
  static const String userOffline = 'user_offline';
  static const String getOnlineUsers = 'get_online_users';
  static const String onlineUsersList = 'online_users_list';

  // Typing Indicator Events
  static const String typingStart = 'typing_start';
  static const String typingStop = 'typing_stop';
  static const String userTyping = 'user_typing';

  // Business / Domain Events
  static const String notification = 'notification';
  static const String agencyTaskAssigned = 'agency_task_assigned';
  static const String agencyStatusUpdate = 'agency_status_update';
  static const String userOrderUpdate = 'user_order_update';
  static const String userServiceRequested = 'user_service_requested';
}
