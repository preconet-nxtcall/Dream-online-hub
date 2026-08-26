class StorageKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String themeMode = 'theme_mode';
  static const String languageCode = 'language_code';

  // Chat server (Node.js) session — separate from PHP auth
  static const String chatToken = 'chat_token';
  static const String chatEmailId = 'chat_email_id';
  static const String chatAgentId = 'chat_agent_id';  // agency's agentId (e.g. AGENCY-23)
  static const String chatUserRole = 'chat_user_role'; // user, agent, admin
}

