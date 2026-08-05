import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/agency/agency_user_item_model.dart';
import '../models/chat/chat_message_model.dart';
import '../repositories/agency_repository.dart';
import '../socket/socket_service.dart';
import '../storage/local_storage_repository.dart';

enum AgencyUserFilterTab { all, unread, online }

class AgencyProvider extends ChangeNotifier {
  final AgencyRepository _agencyRepository;
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
  static const int _limit = 10;
  String _searchQuery = '';
  String? _errorMessage;
  AgencyUserFilterTab _selectedFilter = AgencyUserFilterTab.all;
  String? _activeChatUserId;

  AgencyProvider({
    AgencyRepository? agencyRepository,
    LocalStorageRepository? localStorage,
    SocketService? socketService,
  })  : _agencyRepository = agencyRepository ?? AgencyRepositoryImpl(),
        _localStorage = localStorage ?? LocalStorageRepositoryImpl(),
        _socketService = socketService ?? SocketService.instance {
    _initSocketListeners();
  }

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
      final isOnline = onlineIds.contains(_users[i].id);
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
    final partnerId = message.senderId == 'me' ? message.receiverId : message.senderId;
    final index = _users.indexWhere((u) => u.id == partnerId);

    final isCurrentlyViewing = _activeChatUserId == partnerId;
    final lastMsgPreview = message.type == 'image'
        ? '📷 Image'
        : message.type == 'voice'
            ? '🎤 Voice Note'
            : message.message;

    if (index != -1) {
      final existing = _users.removeAt(index);
      final newUnread = (message.senderId != 'me' && !isCurrentlyViewing)
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
    } else if (partnerId.isNotEmpty && partnerId != 'admin_higher_authority') {
      final newUser = AgencyUserItem(
        id: partnerId,
        name: 'Client $partnerId',
        email: '',
        lastMessage: lastMsgPreview,
        lastActiveTime: message.timestamp,
        unreadCount: message.senderId != 'me' ? 1 : 0,
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

      final onlineSet = _socketService.state.onlineUserIds;
      _users = fetchedUsers.map((u) {
        if (onlineSet.contains(u.id)) {
          return u.copyWith(isOnline: true);
        }
        return u;
      }).toList();

      _hasMore = fetchedUsers.length >= _limit;
      await _localStorage.saveRecentChats(_users);
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
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1 && _users[index].unreadCount > 0) {
      _users[index] = _users[index].copyWith(unreadCount: 0);
      _localStorage.clearUnreadCount(userId);
      _localStorage.saveRecentChats(_users);
      notifyListeners();
    }
  }

  /// Update last message preview and active time when message is sent
  void updateUserLastMessage(String userId, String lastMessage, {DateTime? timestamp}) {
    final index = _users.indexWhere((u) => u.id == userId);
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
