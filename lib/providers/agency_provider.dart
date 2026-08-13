import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import '../models/agency/agency_user_item_model.dart';
import '../models/chat/chat_message_model.dart';
import '../repositories/agency_repository.dart';
import '../socket/socket_service.dart';
import '../storage/local_storage_repository.dart';
import '../utils/date_formatter.dart';

import '../network/api_client.dart';
import '../repositories/chat_repository.dart';

enum AgencyUserFilterTab { all, unread, online }

class AgencyProvider extends ChangeNotifier {
  final AgencyRepository _agencyRepository;
  final ChatRepository _chatRepository;
  final LocalStorageRepository _localStorage;
  final SocketService _socketService;

  StreamSubscription<Set<String>>? _onlineUsersSubscription;
  StreamSubscription<ChatMessageModel>? _messageSubscription;

  List<AgencyUserItem> _users = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _limit = 50;
  String _searchQuery = '';
  String? _errorMessage;
  AgencyUserFilterTab _selectedFilter = AgencyUserFilterTab.all;
  String? _activeChatUserId;

  int _totalRechargeRequestsCount = 0;
  int _pendingRechargeRequestsCount = 0;

  AgencyProvider({
    AgencyRepository? agencyRepository,
    ChatRepository? chatRepository,
    LocalStorageRepository? localStorage,
    SocketService? socketService,
  })  : _agencyRepository = agencyRepository ?? AgencyRepositoryImpl(),
        _chatRepository = chatRepository ?? ChatRepositoryImpl(),
        _localStorage = localStorage ?? LocalStorageRepositoryImpl(),
        _socketService = socketService ?? SocketService.instance {
    _initSocketListeners();
  }

  int get totalRechargeRequestsCount => _totalRechargeRequestsCount;
  int get pendingRechargeRequestsCount => _pendingRechargeRequestsCount;

  void setActiveChatUserId(String? userId) {
    _activeChatUserId = userId;
  }

  void _initSocketListeners() {
    _onlineUsersSubscription = _socketService.onlineUsersStream.listen((onlineIds) {
      _updateOnlineStatuses(onlineIds);
    });

    _messageSubscription = _socketService.messageStream.listen((message) {
      _handleIncomingSocketMessage(message);
    });
  }

  void _updateOnlineStatuses(Set<String> onlineIds) {
    bool hasChanged = false;
    for (int i = 0; i < _users.length; i++) {
      // Match by id OR email since chat server uses emailId as userId
      final isOnline = onlineIds.contains(_users[i].id) ||
          onlineIds.contains(_users[i].email);
      if (_users[i].isOnline != isOnline) {
        _users[i] = _users[i].copyWith(isOnline: isOnline);
        hasChanged = true;
      }
    }
    if (hasChanged) {
      notifyListeners();
    }
  }

  void _handleIncomingSocketMessage(ChatMessageModel message) {
    // The chat server sets senderId / receiverId to the emailId string.
    // isMe is already resolved correctly in ChatMessageDto.
    // The "partner" is whoever is NOT me.
    final partnerId = message.isMe ? message.receiverId : message.senderId;
    // Try to find existing user by id OR email (chat server uses emailId)
    int index = _users.indexWhere((u) => u.id == partnerId);
    if (index == -1) {
      index = _users.indexWhere((u) => u.email == partnerId);
    }

    final isCurrentlyViewing = _activeChatUserId == partnerId ||
        (index >= 0 && index < _users.length &&
            (_activeChatUserId == _users[index].id || _activeChatUserId == _users[index].email));
    final lastMsgPreview = message.type == 'image'
        ? '📷 Image'
        : message.type == 'voice'
            ? '🎤 Voice Note'
            : message.message;

    if (index != -1) {
      final existing = _users.removeAt(index);
      final newUnread = (!message.isMe && !isCurrentlyViewing)
          ? existing.unreadCount + 1
          : existing.unreadCount;

      final updatedUser = existing.copyWith(
        lastMessage: lastMsgPreview,
        lastActiveTime: message.timestamp,
        unreadCount: newUnread,
      );

      _users.insert(0, updatedUser);
      _localStorage.saveRecentChats(_users);
      notifyListeners();
    } else if (partnerId.isNotEmpty &&
        partnerId != ApiEndpoints.adminEmailId &&
        partnerId != ApiEndpoints.adminAgencyUnqId &&
        partnerId != 'admin_higher_authority') {
      final newUser = AgencyUserItem(
        id: partnerId,
        name: 'Client $partnerId',
        email: partnerId.contains('@') ? partnerId : '',
        lastMessage: lastMsgPreview,
        lastActiveTime: message.timestamp,
        unreadCount: !message.isMe ? 1 : 0,
        isOnline: _socketService.state.onlineUserIds.contains(partnerId),
      );
      _users.insert(0, newUser);
      _localStorage.saveRecentChats(_users);
      notifyListeners();
    }
  }

  List<AgencyUserItem> get users => _users;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  AgencyUserFilterTab get selectedFilter => _selectedFilter;

  int get totalUnreadCount => _users.fold(0, (sum, u) => sum + u.unreadCount);
  int get onlineUsersCount => _users.where((u) => u.isOnline).length;

  List<AgencyUserItem> get filteredUsers {
    List<AgencyUserItem> list;
    switch (_selectedFilter) {
      case AgencyUserFilterTab.unread:
        list = _users.where((u) => u.unreadCount > 0).toList();
        break;
      case AgencyUserFilterTab.online:
        list = _users.where((u) => u.isOnline).toList();
        break;
      case AgencyUserFilterTab.all:
        list = List.from(_users);
        break;
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      list = list.where((u) {
        return u.name.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query);
      }).toList();
    }

    return list;
  }

  void setFilter(AgencyUserFilterTab filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Fetch agency users (initial or refresh)
  Future<void> fetchUsers({bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
      _page = 1;
      _hasMore = true;
    } else {
      _isLoading = true;
      _page = 1;
      _hasMore = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedUsers = await _agencyRepository.fetchAgencyUsers(
        page: _page,
        limit: _limit,
        searchQuery: _searchQuery,
      );

      // Fetch real conversations from Node.js chat server (GET /api/v1/conversations)
      final conversations = await _chatRepository.fetchConversations();
      final Map<String, Map<String, dynamic>> convMap = {};
      for (final conv in conversations) {
        final emailObj = conv['emailId'];
        String userEmailId = '';
        String userName = '';
        if (emailObj is Map<String, dynamic>) {
          userEmailId = (emailObj['emailId'] ?? emailObj['_id'] ?? '').toString();
          userName = (emailObj['name'] ?? '').toString();
        } else if (emailObj != null) {
          userEmailId = emailObj.toString();
        }
        if (userEmailId.isNotEmpty) {
          final rawLastMsg = conv['lastMessage'] ?? conv['last_message'] ?? conv['message'];
          String? lastMsgStr;
          if (rawLastMsg is String) {
            lastMsgStr = rawLastMsg;
          } else if (rawLastMsg is Map) {
            lastMsgStr = (rawLastMsg['text'] ?? rawLastMsg['content'] ?? '').toString();
          }

          convMap[userEmailId] = {
            'conv': conv,
            'userName': userName,
            'unreadCount': (conv['unread'] is Map) ? (conv['unread']['agent'] ?? 0) : 0,
            'lastMessage': (lastMsgStr != null && lastMsgStr.isNotEmpty) ? lastMsgStr : null,
            'lastMessageAt': conv['lastMessageAt'] != null ? DateFormatter.parseToLocal(conv['lastMessageAt']) : null,
          };
        }
      }

      final onlineSet = _socketService.state.onlineUserIds;
      _users = fetchedUsers.map((u) {
        final convData = convMap[u.id] ?? convMap[u.email];
        final isOnline = onlineSet.contains(u.id) || onlineSet.contains(u.email);
        if (convData != null) {
          final unread = (convData['unreadCount'] as int? ?? 0);
          final lastActive = (convData['lastMessageAt'] as DateTime?) ?? u.lastActiveTime;
          final lastMsg = (convData['lastMessage'] as String?) ?? u.lastMessage;
          return u.copyWith(
            isOnline: isOnline,
            unreadCount: unread > 0 ? unread : u.unreadCount,
            lastActiveTime: lastActive,
            lastMessage: lastMsg,
          );
        }
        return u.copyWith(isOnline: isOnline);
      }).toList();

      // Update _users with chat conversation info from chat server
      // Note: Only users assigned to this agency are retained in _users
      if (fetchedUsers.isEmpty) {
        for (final entry in convMap.entries) {
          final userEmailId = entry.key;
          final info = entry.value;
          final exists = _users.any((u) => u.id == userEmailId || u.email == userEmailId);
          if (!exists && userEmailId.isNotEmpty) {
            final isOnline = onlineSet.contains(userEmailId);
            final unread = (info['unreadCount'] as int? ?? 0);
            final userName = (info['userName'] as String?).toString().isNotEmpty
                ? info['userName'] as String
                : 'User $userEmailId';
            _users.insert(
              0,
              AgencyUserItem(
                id: userEmailId,
                name: userName,
                email: userEmailId,
                unreadCount: unread,
                isOnline: isOnline,
                lastMessage: info['lastMessage'] as String?,
                lastActiveTime: info['lastMessageAt'] as DateTime?,
              ),
            );
          }
        }
      }

      _hasMore = fetchedUsers.length >= _limit;
      await _localStorage.saveRecentChats(_users);

      // Async fetch agency live recharge statistics from database
      unawaited(fetchRechargeStats());
    } catch (e) {
      _errorMessage = 'Failed to load agency users. Tap to retry.';
      final cached = _localStorage.getCachedRecentChats();
      if (cached.isNotEmpty) {
        _users = cached;
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Fetch live agency recharge statistics from database
  Future<void> fetchRechargeStats() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.post(
        ApiEndpoints.getQrCode,
        data: {
          'action': 'recharge_records',
        },
      );

      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        final rawList = (response.data['data'] is List
            ? response.data['data'] as List
            : (response.data['recharges'] is List ? response.data['recharges'] as List : []));

        _totalRechargeRequestsCount = rawList.length;
        _pendingRechargeRequestsCount = rawList.where((item) {
          final status = (item['stage_status'] ?? item['status'] ?? '').toString().toLowerCase();
          return status.contains('pending');
        }).length;
        notifyListeners();
      }
    } catch (_) {
      final localList = _localStorage.getSubmittedRecharges();
      _totalRechargeRequestsCount = localList.length;
      _pendingRechargeRequestsCount = localList.where((item) {
        final status = (item is Map ? item['status'] : (item as dynamic).status).toString().toLowerCase();
        return status.contains('pending');
      }).length;
      notifyListeners();
    }
  }

  /// Load next page for pagination
  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMore || _isLoading || _isRefreshing) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _page + 1;
      final newUsers = await _agencyRepository.fetchAgencyUsers(
        page: nextPage,
        limit: _limit,
        searchQuery: _searchQuery,
      );

      if (newUsers.isNotEmpty) {
        final onlineSet = _socketService.state.onlineUserIds;
        final processedNewUsers = newUsers.map((u) {
          if (onlineSet.contains(u.id)) {
            return u.copyWith(isOnline: true);
          }
          return u;
        }).toList();

        _users.addAll(processedNewUsers);
        _page = nextPage;
        _hasMore = newUsers.length >= _limit;
        await _localStorage.saveRecentChats(_users);
      } else {
        _hasMore = false;
      }
    } catch (e) {
      // Keep existing users on pagination error
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Instant search filter
  void search(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    notifyListeners();
  }

  /// Mark unread messages as read when opening user conversation
  void markUserAsRead(String userId) {
    _activeChatUserId = userId;
    final index = _users.indexWhere((u) => u.id == userId || u.email == userId);
    if (index != -1 && _users[index].unreadCount > 0) {
      _users[index] = _users[index].copyWith(unreadCount: 0);
      _localStorage.clearUnreadCount(userId);
      _localStorage.saveRecentChats(_users);
      notifyListeners();
    }
  }

  /// Update last message preview and active time when message is sent
  void updateUserLastMessage(String userId, String lastMessage, {DateTime? timestamp}) {
    final index = _users.indexWhere((u) => u.id == userId || u.email == userId);
    if (index != -1) {
      final updated = _users.removeAt(index).copyWith(
        lastMessage: lastMessage,
        lastActiveTime: timestamp ?? DateTime.now(),
        unreadCount: 0,
      );
      _users.insert(0, updated);
      _localStorage.clearUnreadCount(userId);
      _localStorage.saveRecentChats(_users);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _onlineUsersSubscription?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }
}
