import 'dart:convert';
import '../models/agency/agency_user_item_model.dart';
import '../models/chat/chat_message_model.dart';
import '../models/common/user_model.dart';
import '../models/user/recharge_record_model.dart';
import 'local_storage_service.dart';

abstract class LocalStorageRepository {
  // Auth & Tokens
  Future<void> saveUser(UserModel user);
  UserModel? getUser();
  Future<void> saveTokens({required String accessToken, String? refreshToken});
  String? getAccessToken();
  String? getRefreshToken();
  Future<void> clearAuthData();

  // Chats & Messages
  Future<void> saveMessages(String userId, List<ChatMessageModel> messages);
  List<ChatMessageModel> getCachedMessages(String userId);
  Future<void> saveRecentChats(List<AgencyUserItem> recentChats);
  List<AgencyUserItem> getCachedRecentChats();

  // Theme Mode
  Future<void> saveThemeMode(String themeMode);
  String getThemeMode();

  // Offline Queue
  Future<void> saveOfflineQueue(List<Map<String, dynamic>> queue);
  List<Map<String, dynamic>> getOfflineQueue();
  Future<void> clearOfflineQueue();

  // Unread Counts
  Future<void> setUnreadCount(String userId, int count);
  int getUnreadCount(String userId);
  Future<void> incrementUnread(String userId);
  Future<void> clearUnreadCount(String userId);

  // Recharge Persistence
  Future<void> saveSubmittedRecharge(dynamic record);
  List<dynamic> getSubmittedRecharges();
}

class LocalStorageRepositoryImpl implements LocalStorageRepository {
  final LocalStorageService _storageService;

  LocalStorageRepositoryImpl({LocalStorageService? storageService})
      : _storageService = storageService ?? HiveLocalStorageService();

  // Keys
  static const String _userKey = 'logged_user';
  static const String _accessTokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  static const String _recentChatsKey = 'recent_chats_list';
  static const String _themeModeKey = 'app_theme_mode';
  static const String _offlineQueueKey = 'offline_pending_queue';

  @override
  Future<void> saveUser(UserModel user) async {
    final box = _storageService.authBox;
    if (box == null) return;
    final jsonStr = jsonEncode(user.toJson());
    await box.put(_userKey, jsonStr);
  }

  @override
  UserModel? getUser() {
    try {
      final box = _storageService.authBox;
      if (box == null) return null;
      final raw = box.get(_userKey);
      if (raw == null) return null;

      if (raw is String && raw.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(raw);
        return UserModel.fromJson(jsonMap);
      } else if (raw is Map) {
        final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(raw);
        return UserModel.fromJson(jsonMap);
      } else if (raw is UserModel) {
        return raw;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    final box = _storageService.authBox;
    if (box == null) return;
    await box.put(_accessTokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await box.put(_refreshTokenKey, refreshToken);
    }
  }

  @override
  String? getAccessToken() {
    final box = _storageService.authBox;
    if (box == null) return null;
    return box.get(_accessTokenKey)?.toString();
  }

  @override
  String? getRefreshToken() {
    final box = _storageService.authBox;
    if (box == null) return null;
    return box.get(_refreshTokenKey)?.toString();
  }

  @override
  Future<void> clearAuthData() async {
    final box = _storageService.authBox;
    if (box == null) return;
    await box.delete(_userKey);
    await box.delete(_accessTokenKey);
    await box.delete(_refreshTokenKey);
  }

  @override
  Future<void> saveMessages(String userId, List<ChatMessageModel> messages) async {
    final box = _storageService.chatsBox;
    if (box == null) return;

    final List<ChatMessageModel> deduplicated = [];
    for (final m in messages) {
      final text = m.message.trim();
      final isRequestMsg = text.contains('RECHARGE') ||
          text.contains('WITHDRAW') ||
          text.contains('REQUEST');
      final exists = deduplicated.any((item) =>
          (m.id.isNotEmpty && item.id == m.id) ||
          (isRequestMsg &&
              item.message.trim() == text &&
              item.isMe == m.isMe &&
              item.timestamp.difference(m.timestamp).abs().inSeconds <= 60));
      if (!exists) {
        deduplicated.add(m);
      }
    }

    final List<Map<String, dynamic>> jsonList = deduplicated.map((m) => {
      'id': m.id,
      'sender_id': m.senderId,
      'receiver_id': m.receiverId,
      'message': m.message,
      'timestamp': m.timestamp.toIso8601String(),
      'status': m.status,
      'type': m.type,
      'image_url': m.imageUrl,
      'audio_url': m.audioUrl,
      'voice_duration': m.voiceDuration,
      'reply_to_message': m.replyToMessage,
      'is_me': m.isMe,
      'local_file_path': m.localFilePath,
    }).toList();

    await box.put('messages_$userId', jsonEncode(jsonList));
  }

  @override
  List<ChatMessageModel> getCachedMessages(String userId) {
    final box = _storageService.chatsBox;
    if (box == null) return [];
    final raw = box.get('messages_$userId');
    if (raw is String && raw.isNotEmpty) {
      try {
        final cachedUser = getUser();
        final authBox = _storageService.authBox;
        final chatEmailId = authBox?.get('chat_email_id')?.toString();
        final userIdStored = authBox?.get('user_id')?.toString();
        final agentIdStored = authBox?.get('chat_agent_id')?.toString();
        final userRole = authBox?.get('chat_user_role')?.toString() ??
            authBox?.get('user_role')?.toString() ??
            cachedUser?.role ??
            'user';

        final roleLower = userRole.trim().toLowerCase();
        final isCurrentUserAgentOrAdmin =
            roleLower == 'agent' || roleLower == 'agency' || roleLower == 'admin';

        final userKeys = {
          'me',
          if (cachedUser?.email != null && cachedUser!.email.isNotEmpty) cachedUser.email.trim().toLowerCase(),
          if (cachedUser?.id != null && cachedUser!.id.isNotEmpty) cachedUser.id.trim().toLowerCase(),
          if (chatEmailId != null && chatEmailId.isNotEmpty) chatEmailId.trim().toLowerCase(),
          if (userIdStored != null && userIdStored.isNotEmpty) userIdStored.trim().toLowerCase(),
          if (isCurrentUserAgentOrAdmin && agentIdStored != null && agentIdStored.isNotEmpty)
            agentIdStored.trim().toLowerCase(),
        };

        final List jsonList = jsonDecode(raw);
        return jsonList.map((m) {
          final map = m is Map<String, dynamic> ? m : <String, dynamic>{};
          return ChatMessageModel.fromJson(map, userKeys: userKeys, userRole: userRole);
        }).toList();
      } catch (_) {}
    }
    return [];
  }

  @override
  Future<void> saveRecentChats(List<AgencyUserItem> recentChats) async {
    final box = _storageService.chatsBox;
    if (box == null) return;
    final List<Map<String, dynamic>> jsonList = recentChats.map((u) => u.toJson()).toList();
    await box.put(_recentChatsKey, jsonEncode(jsonList));
  }

  @override
  List<AgencyUserItem> getCachedRecentChats() {
    final box = _storageService.chatsBox;
    if (box == null) return [];
    final raw = box.get(_recentChatsKey);
    if (raw is String && raw.isNotEmpty) {
      try {
        final List jsonList = jsonDecode(raw);
        return jsonList.map((item) => AgencyUserItem.fromJson(item is Map<String, dynamic> ? item : {})).toList();
      } catch (_) {}
    }
    return [];
  }

  @override
  Future<void> saveThemeMode(String themeMode) async {
    final box = _storageService.settingsBox;
    if (box == null) return;
    await box.put(_themeModeKey, themeMode);
  }

  @override
  String getThemeMode() {
    final box = _storageService.settingsBox;
    if (box == null) return 'light';
    return box.get(_themeModeKey, defaultValue: 'light').toString();
  }

  @override
  Future<void> saveOfflineQueue(List<Map<String, dynamic>> queue) async {
    final box = _storageService.offlineQueueBox;
    if (box == null) return;
    await box.put(_offlineQueueKey, jsonEncode(queue));
  }

  @override
  List<Map<String, dynamic>> getOfflineQueue() {
    final box = _storageService.offlineQueueBox;
    if (box == null) return [];
    final raw = box.get(_offlineQueueKey);
    if (raw is String && raw.isNotEmpty) {
      try {
        final List jsonList = jsonDecode(raw);
        return jsonList.cast<Map<String, dynamic>>();
      } catch (_) {}
    }
    return [];
  }

  @override
  Future<void> clearOfflineQueue() async {
    final box = _storageService.offlineQueueBox;
    if (box == null) return;
    await box.delete(_offlineQueueKey);
  }

  @override
  Future<void> setUnreadCount(String userId, int count) async {
    final box = _storageService.unreadBox;
    if (box == null) return;
    await box.put('unread_$userId', count);
  }

  @override
  int getUnreadCount(String userId) {
    final box = _storageService.unreadBox;
    if (box == null) return 0;
    return (box.get('unread_$userId', defaultValue: 0) as num).toInt();
  }

  @override
  Future<void> incrementUnread(String userId) async {
    final current = getUnreadCount(userId);
    await setUnreadCount(userId, current + 1);
  }

  @override
  Future<void> clearUnreadCount(String userId) async {
    await setUnreadCount(userId, 0);
  }

  @override
  Future<void> saveSubmittedRecharge(dynamic record) async {
    final box = _storageService.chatsBox;
    if (box == null) return;
    final existing = getSubmittedRecharges();
    final recId = (record is Map) ? record['id'] : record.id;
    final recBook = (record is Map) ? record['bookName'] : record.bookName;
    final recDetails = (record is Map) ? record['transactionDetails'] : record.transactionDetails;
    final recAmount = (record is Map) ? record['amount'] : record.amount;
    final recStatus = (record is Map) ? record['status'] : record.status;
    final recDate = (record is Map) ? record['date'] : record.date;
    final recImageUrl = (record is Map) ? (record['imageUrl'] ?? record['image_url']) : (record is RechargeRecordModel ? record.imageUrl : null);
    final recInvoiceUrl = (record is Map) ? (record['invoiceUrl'] ?? record['invoice_url']) : (record is RechargeRecordModel ? record.invoiceUrl : null);

    existing.removeWhere((r) => (r is Map ? r['id'] : r.id) == recId);
    existing.insert(0, {
      'id': recId,
      'bookName': recBook,
      'transactionDetails': recDetails,
      'amount': recAmount,
      'status': recStatus,
      'date': recDate,
      'imageUrl': recImageUrl,
      'invoiceUrl': recInvoiceUrl,
    });

    await box.put('submitted_recharges_list', jsonEncode(existing));
  }

  @override
  List<dynamic> getSubmittedRecharges() {
    final box = _storageService.chatsBox;
    if (box == null) return [];
    final raw = box.get('submitted_recharges_list');
    if (raw is String && raw.isNotEmpty) {
      try {
        final List list = jsonDecode(raw);
        return list;
      } catch (_) {}
    }
    return [];
  }
}
