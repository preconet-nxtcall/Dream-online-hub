class SocketEvents {
  // Connection & Lifecycle Events
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String connectError = 'connect_error';
  static const String reconnect = 'reconnect';
  static const String reconnecting = 'reconnecting';
  static const String ping = 'ping';
  static const String pong = 'pong';


  // Real-Time Chat Messaging Events (Matching API Documentation)
  static const String sendMessage = 'message:send';
  static const String receiveMessage = 'message:new';
  static const String messageSent = 'message:sent';
  static const String messageQueued = 'message:queued';
  static const String messageAck = 'message_ack';
  static const String messageDelivered = 'message:delivered';
  static const String messageRead = 'message:read';

  // Legacy event aliases for full compatibility
  static const String sendMessageLegacy = 'send_message';
  static const String receiveMessageLegacy = 'receive_message';

  // Presence / Online Status Events
  static const String presenceCheck = 'presence:check';
  static const String presenceRes = 'presence:res';
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















