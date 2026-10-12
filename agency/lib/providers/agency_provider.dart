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
  int _totalWithdrawRequestsCount = 0;
  int _pendingWithdrawRequestsCount = 0;
  bool _hasSeenNotifications = false;

  AgencyProvider({
    AgencyRepository? agencyRepository,
    LocalStorageRepository? localStorage,
  })  : _agencyRepository = agencyRepository ?? AgencyRepositoryImpl(),
        _localStorage = localStorage ?? LocalStorageRepositoryImpl();

  int get totalRechargeRequestsCount => _totalRechargeRequestsCount;
  int get pendingRechargeRequestsCount => _pendingRechargeRequestsCount;
  int get totalWithdrawRequestsCount => _totalWithdrawRequestsCount;
  int get pendingWithdrawRequestsCount => _pendingWithdrawRequestsCount;
  int get totalRequestsCount => _totalRechargeRequestsCount + _totalWithdrawRequestsCount;
  int get totalPendingRequestsCount => _pendingRechargeRequestsCount + _pendingWithdrawRequestsCount;
  bool get hasSeenNotifications => _hasSeenNotifications;

  int get unseenNotificationCount {
    if (_hasSeenNotifications) return 0;
    return _pendingRechargeRequestsCount + _pendingWithdrawRequestsCount;
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

      // Async fetch agency live recharge & withdrawal statistics from database
      unawaited(fetchRechargeStats());
    } catch (e) {
      _errorMessage = 'Failed to load agency users. Tap to retry.';
      _users = [];
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Fetch live agency recharge & withdrawal statistics with strict agency isolation
  Future<void> fetchRechargeStats() async {
    try {
      final apiClient = ApiClient();
      final currentUser = _localStorage.getUser();
      final agencyIdSet = <String>{};

      if (currentUser != null) {
        if (currentUser.id.isNotEmpty) {
          agencyIdSet.add(currentUser.id.trim());
          final cleanId = currentUser.id.replaceAll(RegExp(r'\D'), '');
          if (cleanId.isNotEmpty) agencyIdSet.add(cleanId);
        }
        if (currentUser.agencyId != null && currentUser.agencyId!.isNotEmpty) {
          agencyIdSet.add(currentUser.agencyId!.trim());
          final cleanAg = currentUser.agencyId!.replaceAll(RegExp(r'\D'), '');
          if (cleanAg.isNotEmpty) agencyIdSet.add(cleanAg);
        }
        if (currentUser.agencyUnqId != null && currentUser.agencyUnqId!.isNotEmpty) {
          agencyIdSet.add(currentUser.agencyUnqId!.trim());
          final cleanUnq = currentUser.agencyUnqId!.replaceAll(RegExp(r'\D'), '');
          if (cleanUnq.isNotEmpty) agencyIdSet.add(cleanUnq);
        }
      }

      List<dynamic> extractRawList(dynamic data) {
        final List raw = [];
        if (data is Map<String, dynamic>) {
          final rawData = data['data'];
          if (rawData is List) {
            raw.addAll(rawData);
          } else if (rawData is Map<String, dynamic>) {
            if (rawData['pending'] is List) raw.addAll(rawData['pending'] as List);
            if (rawData['successful'] is List) raw.addAll(rawData['successful'] as List);
            if (rawData['rejected'] is List) raw.addAll(rawData['rejected'] as List);
          } else if (data['recharges'] is List) {
            raw.addAll(data['recharges'] as List);
          } else if (data['withdrawals'] is List) {
            raw.addAll(data['withdrawals'] as List);
          } else if (data['categorized'] is Map) {
            final cat = data['categorized'] as Map;
            if (cat['pending'] is List) raw.addAll(cat['pending'] as List);
            if (cat['successful'] is List) raw.addAll(cat['successful'] as List);
            if (cat['rejected'] is List) raw.addAll(cat['rejected'] as List);
          }
        } else if (data is List) {
          raw.addAll(data);
        }

        // Deduplicate records by unique ID to guarantee exact database count
        final seenIds = <String>{};
        final List deduplicated = [];
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            final id = (item['id'] ?? item['recharge_id'] ?? item['withdrawal_id'])?.toString();
            if (id != null && id.isNotEmpty) {
              if (seenIds.contains(id)) continue;
              seenIds.add(id);
            }
          }
          deduplicated.add(item);
        }
        return deduplicated;
      }

      dynamic rechargeData;
      dynamic withdrawData;

      try {
        final res = await apiClient.post(
          ApiEndpoints.getQrCode,
          data: {'action': 'recharge_records', 'status_type': 'all'},
        );
        rechargeData = res.data;
      } catch (_) {}

      try {
        final res = await apiClient.post(
          ApiEndpoints.getQrCode,
          data: {'action': 'withdraw_records', 'status_type': 'all'},
        );
        withdrawData = res.data;
      } catch (_) {}

      // 1. Process Recharges strictly for this agency ID
      if (rechargeData != null) {
        final rawRecharges = extractRawList(rechargeData);
        final agencyRecharges = rawRecharges.where((item) {
          if (item is! Map<String, dynamic>) return false;
          if (agencyIdSet.isNotEmpty) {
            final rEmpId = (item['emp_id'] ?? item['agency_id'])?.toString().trim();
            if (rEmpId == null || rEmpId.isEmpty) return false;
            final rEmpClean = rEmpId.replaceAll(RegExp(r'\D'), '');
            return agencyIdSet.contains(rEmpId) || (rEmpClean.isNotEmpty && agencyIdSet.contains(rEmpClean));
          }
          return true;
        }).toList();

        _totalRechargeRequestsCount = agencyRecharges.length;
        _pendingRechargeRequestsCount = agencyRecharges.where((item) {
          final status = (item['stage_status'] ?? item['status'] ?? item['stage'] ?? '').toString().trim().toUpperCase();
          return status.contains('PENDING') ||
              status == '0' ||
              status == 'CREATED' ||
              status == 'SUBMITTED' ||
              status.contains('PROGRESS') ||
              status == 'NEW';
        }).length;
      }

      // 2. Process Withdrawals strictly for this agency ID
      if (withdrawData != null) {
        final rawWithdraws = extractRawList(withdrawData);
        final agencyWithdraws = rawWithdraws.where((item) {
          if (item is! Map<String, dynamic>) return false;
          if (agencyIdSet.isNotEmpty) {
            final wEmpId = (item['agency_id'] ?? item['emp_id'])?.toString().trim();
            if (wEmpId == null || wEmpId.isEmpty) return false;
            final wEmpClean = wEmpId.replaceAll(RegExp(r'\D'), '');
            return agencyIdSet.contains(wEmpId) || (wEmpClean.isNotEmpty && agencyIdSet.contains(wEmpClean));
          }
          return true;
        }).toList();

        _totalWithdrawRequestsCount = agencyWithdraws.length;
        _pendingWithdrawRequestsCount = agencyWithdraws.where((item) {
          final status = (item['stage_status'] ?? item['status'] ?? item['stage'] ?? '').toString().trim().toUpperCase();
          return status.contains('PENDING') ||
              status == 'EMPLOYEE-PENDING' ||
              status == 'AGENCY-PENDING' ||
              status == '0' ||
              status == 'CREATED' ||
              status == 'SUBMITTED';
        }).length;
      }

      notifyListeners();
    } catch (_) {
      // Keep existing count on error
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
