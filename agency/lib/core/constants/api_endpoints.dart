class ApiEndpoints {
  // ─── PHP Office Manager (Login, User/Agency Profile) ───────────────────────
  static const String baseUrl = 'https://dreamonlinehub.club/';

  // ─── Chat Server (Node.js + Socket.IO — Production) ─────────────────────────
  static const String chatBaseUrl = 'https://dreamonlinehub.club/chat';
  static const String chatSocketUrl = 'https://dreamonlinehub.club/';
  static const String fixedToken = 'chat_fixed_auth_token_2026_prod';

  // ─── PHP Auth ───────────────────────────────────────────────────────────────
  static const String login = 'api.php';       // POST api.php { action: 'login', ... }
  static const String register = 'api.php';    // POST api.php { action: 'register', ... }
  static const String logout = 'api.php';      // POST api.php { action: 'logout' }
  static const String profile = 'api.php';     // GET  api.php { action: 'profile' }
  static const String refreshToken = 'api.php';// POST api.php { action: 'refresh_token' }
  static const String getQrCode = 'api.php';   // POST api.php { action: 'get_qr_code', ... }

  // ─── Chat Server: Auth ──────────────────────────────────────────────────────
  /// POST /api/v1/auth/login — { emailId, password } → { token, user }
  static const String chatLogin = '/api/v1/auth/login';

  // ─── Chat Server: Conversations ─────────────────────────────────────────────
  /// GET /api/v1/conversations
  static const String conversations = '/api/v1/conversations';
  /// GET /api/v1/conversations/:conversationId/messages
  static String conversationMessages(String conversationId) =>
      '/api/v1/conversations/${Uri.encodeComponent(conversationId)}/messages';

  // ─── Chat Server: Voice ──────────────────────────────────────────────────────
  static const String presignedVoice = '/api/v1/voice/presigned-url';
  static const String playVoice = '/api/v1/voice/play-url';

  // ─── Chat Server: Image ──────────────────────────────────────────────────────
  static const String presignedImage = '/api/v1/image/presigned-url';
  static const String playImage = '/api/v1/image/play-url';

  // ─── Higher Authority (Admin) Chat Identity ──────────────────────────────────
  /// Real admin email from DB — used as recipientId for Higher Authority chat.
  static const String adminEmailId = 'admin@gmail.com';
  /// Real admin agency unique ID from DB (agency_unq_id column).
  static const String adminAgencyUnqId = 'ADMIN-1';

  // ─── Chat Server: Admin / Agency Management ──────────────────────────────────
  static const String adminAgents = '/api/v1/admin/agents';
  static const String adminUsers = '/api/v1/admin/users';
  static const String adminAssign = '/api/v1/admin/users/assign';

  // ─── Chat Server: Games ──────────────────────────────────────────────────────
  static const String games = '/api/v1/games';
  static const String gameSubscribe = '/api/v1/games/subscribe';

  // ─── Conversation ID Builder ─────────────────────────────────────────────────
  /// Mirrors the server convention: conv-{agentId}-{userEmailId}
  static String buildConversationId(String agentId, String userEmailId) =>
      'conv-$agentId-$userEmailId';

  /// User App conversation ID format: {user_email}-{agency_id} (e.g. sample@gmail.com-23)
  static String buildUserAgencyConversationId(String userEmail, String agencyId) {
    final cleanAgencyId = agencyId.replaceAll(RegExp(r'^\s*AGENCY-?\s*', caseSensitive: false), '').trim();
    return '$userEmail-$cleanAgencyId';
  }

  // ─── Socket URL (legacy alias, kept for SocketService) ───────────────────────
  static const String socketUrl = chatSocketUrl;
}
