import 'dart:async';

import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import '../models/agency/agency_user_item_model.dart';
import '../repositories/agency_repository.dart';
import '../storage/local_storage_repository.dart';
import '../network/api_client.dart';

enum AgencyUserFilterTab { all, unread, online }

class AgencyProvider extends ChangeNotifier {
  final AgencyRepository _agencyRepository;
  final LocalStorageRepository _localStorage;

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

  int _totalRechargeRequestsCount = 0;
  int _pendingRechargeRequestsCount = 0;
  bool _hasSeenNotifications = false;

  AgencyProvider({
    AgencyRepository? agencyRepository,
    LocalStorageRepository? localStorage,
  })  : _agencyRepository = agencyRepository ?? AgencyRepositoryImpl(),
        _localStorage = localStorage ?? LocalStorageRepositoryImpl();

  int get totalRechargeRequestsCount => _totalRechargeRequestsCount;
  int get pendingRechargeRequestsCount => _pendingRechargeRequestsCount;
  bool get hasSeenNotifications => _hasSeenNotifications;

  int get unseenNotificationCount {
    if (_hasSeenNotifications) return 0;
    return _pendingRechargeRequestsCount;
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

      _users = fetchedUsers;
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

      final data = response.data;
      if (data is Map<String, dynamic> && (data['success'] == true || data['status'] == 'success' || data['data'] != null)) {
        final List rawList = [];
        final rawData = data['data'];
        if (rawData is List) {
          rawList.addAll(rawData);
        } else if (rawData is Map<String, dynamic>) {
          if (rawData['pending'] is List) rawList.addAll(rawData['pending'] as List);
          if (rawData['successful'] is List) rawList.addAll(rawData['successful'] as List);
          if (rawData['rejected'] is List) rawList.addAll(rawData['rejected'] as List);
        } else if (data['recharges'] is List) {
          rawList.addAll(data['recharges'] as List);
        }

        final currentUser = _localStorage.getUser();
        final currentAgencyId = (currentUser?.agencyId != null && currentUser!.agencyId!.isNotEmpty)
            ? currentUser.agencyId!.replaceAll(RegExp(r'\D'), '')
            : (currentUser?.id != null ? currentUser!.id.replaceAll(RegExp(r'\D'), '') : '');

        final agencyList = rawList.where((item) {
          if (item is! Map<String, dynamic>) return false;
          if (currentAgencyId.isNotEmpty) {
            final itemEmpId = (item['emp_id'] ?? item['agency_id'])?.toString().replaceAll(RegExp(r'\D'), '');
            if (itemEmpId != null && itemEmpId.isNotEmpty && itemEmpId != currentAgencyId) {
              return false;
            }
          }
          return true;
        }).toList();

        _totalRechargeRequestsCount = agencyList.length;
        final newPendingCount = agencyList.where((item) {
          final status = (item['stage_status'] ?? item['status'] ?? item['stage'] ?? '').toString().trim().toLowerCase();
          return status.contains('pending') ||
              status == '0' ||
              status == 'created' ||
              status == 'submitted' ||
              status.contains('progress') ||
              status == 'new';
        }).length;

        if (newPendingCount > _pendingRechargeRequestsCount) {
          _hasSeenNotifications = false;
        }
        _pendingRechargeRequestsCount = newPendingCount;
        notifyListeners();
      }
    } catch (_) {
      final localList = _localStorage.getSubmittedRecharges();
      _totalRechargeRequestsCount = localList.length;
      final newPendingCount = localList.where((item) {
        final status = (item is Map ? (item['status'] ?? item['stage_status']) : (item as dynamic).status).toString().trim().toLowerCase();
        return status.contains('pending') ||
            status == '0' ||
            status == 'created' ||
            status == 'submitted' ||
            status.contains('progress') ||
            status == 'new';
      }).length;

      if (newPendingCount > _pendingRechargeRequestsCount) {
        _hasSeenNotifications = false;
      }
      _pendingRechargeRequestsCount = newPendingCount;
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
        _users.addAll(newUsers);
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

  /// Mark all notifications as seen and clear unread count badge
  void markNotificationsAsSeen() {
    _hasSeenNotifications = true;
    notifyListeners();
  }

  /// Mark all unread messages as read across all agency clients
  void markAllAsRead() {
    _hasSeenNotifications = true;
    notifyListeners();
  }
}
