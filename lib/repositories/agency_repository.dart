import '../core/constants/api_endpoints.dart';
import '../core/errors/exceptions.dart';
import '../models/agency/agency_model.dart';
import '../models/agency/agency_user_item_model.dart';
import '../network/api_client.dart';
import '../storage/local_storage_repository.dart';
import '../utils/logger.dart';

abstract class AgencyRepository {
  Future<AgencyModel> getAgencyDetails(String agencyId);
  Future<List<AgencyUserItem>> fetchAgencyUsers({
    required int page,
    required int limit,
    String? searchQuery,
  });
  Future<bool> createUser(String name, String email, String mob, String password);
  Future<bool> updateUser(int id, String name);
  Future<bool> deleteUser(int id);
}

class AgencyRepositoryImpl implements AgencyRepository {
  final ApiClient _apiClient;
  final LocalStorageRepository _localStorage;

  AgencyRepositoryImpl({
    ApiClient? apiClient,
    LocalStorageRepository? localStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _localStorage = localStorage ?? LocalStorageRepositoryImpl();

  @override
  Future<AgencyModel> getAgencyDetails(String agencyId) async {
    // PHP api.php has no 'get_agency' action.
    // Return agency details from the logged-in user stored in local cache.
    try {
      final cachedUser = _localStorage.getUser();
      return AgencyModel(
        agencyId: agencyId,
        agencyName: cachedUser?.name ?? 'Agency',
        activeAgents: 0,
      );
    } catch (e) {
      throw ServerException(message: 'Failed to fetch agency details');
    }
  }

  @override
  Future<List<AgencyUserItem>> fetchAgencyUsers({
    required int page,
    required int limit,
    String? searchQuery,
  }) async {
    try {
      final currentUser = _localStorage.getUser();
      final currentAgencyId = (currentUser?.agencyId != null && currentUser!.agencyId!.isNotEmpty)
          ? currentUser.agencyId!
          : (currentUser?.id.toString() ?? '');

      List<dynamic> rawList = [];

      // 1. Fetch all users via 'read_users' action
      try {
        final res = await _apiClient.post(
          ApiEndpoints.login, // api.php
          data: {'action': 'read_users'},
        );
        final resData = res.data;
        if (resData is Map<String, dynamic> && resData['success'] != false) {
          final list = resData['data'] ?? resData['users'] ?? [];
          if (list is List && list.isNotEmpty) {
            rawList = list;
          }
        }
      } catch (_) {}

      // 2. If 'read_users' returned empty, try 'get_by_agency_id'
      if (rawList.isEmpty && currentAgencyId.isNotEmpty) {
        try {
          final res = await _apiClient.post(
            ApiEndpoints.login,
            data: {
              'action': 'get_by_agency_id',
              'agency_id': currentAgencyId,
            },
          );
          final resData = res.data;
          if (resData is Map<String, dynamic> && resData['success'] != false) {
            final list = resData['data'] ?? resData['users'] ?? [];
            if (list is List && list.isNotEmpty) {
              rawList = list;
            }
          }
        } catch (_) {}
      }

      final rawAgencyId = currentAgencyId;
      final cleanAgencyId = rawAgencyId.replaceAll(RegExp(r'^\D+'), '');

      List<dynamic> extractAssignedUsers(List<dynamic> inputList, {bool strictAgencyCheck = true}) {
        return inputList.where((item) {
          if (item is! Map<String, dynamic>) return false;
          final type = (item['type'] ?? item['role'] ?? '').toString().toUpperCase();
          if (type != 'USER') return false;

          final itemEmail = (item['email'] ?? '').toString().trim().toLowerCase();
          final itemId = (item['id'] ?? '').toString().trim();
          final myEmail = (currentUser?.email ?? '').trim().toLowerCase();

          // Exclude Admin and Agency's own account
          if (itemEmail == myEmail || itemEmail == 'admin@gmail.com' || itemId == '1' || itemId == cleanAgencyId) {
            return false;
          }

          if (strictAgencyCheck && rawAgencyId.isNotEmpty) {
            final rawUserAgency = (item['agency_id'] ?? item['emp_id'] ?? '').toString().trim();
            if (rawUserAgency.isNotEmpty) {
              final userAgencyClean = rawUserAgency.replaceAll(RegExp(r'^\D+'), '');
              final currentAgencyClean = cleanAgencyId;
              final fullAgencyUnqId = 'AGENCY-$cleanAgencyId';

              final isMatched = rawUserAgency == rawAgencyId ||
                  rawUserAgency == fullAgencyUnqId ||
                  (userAgencyClean.isNotEmpty && userAgencyClean == currentAgencyClean);

              if (!isMatched) return false;
            }
          }

          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            final q = searchQuery.trim().toLowerCase();
            final name  = (item['name']  ?? '').toString().toLowerCase();
            final email = (item['email'] ?? '').toString().toLowerCase();
            final mob   = (item['mob']   ?? '').toString().toLowerCase();
            return name.contains(q) || email.contains(q) || mob.contains(q);
          }
          return true;
        }).toList();
      }

      // Try strict agency matching first
      var filtered = extractAssignedUsers(rawList, strictAgencyCheck: true);

      // If strict filter yields no users, fallback to showing all valid USER accounts
      if (filtered.isEmpty && rawList.isNotEmpty) {
        filtered = extractAssignedUsers(rawList, strictAgencyCheck: false);
      }

      // Apply pagination
      final offset = (page - 1) * limit;
      final paginated = filtered.skip(offset).take(limit).toList();

      List<AgencyUserItem> users = paginated
          .map((item) => AgencyUserItem.fromJson(item as Map<String, dynamic>))
          .toList();

      if (users.isNotEmpty) {
        await _localStorage.saveRecentChats(users);
        AppLogger.info('fetchAgencyUsers: Loaded ${users.length} assigned users from API.');
        return users;
      }

      // No data from API — try sanitized cache
      final cached = _localStorage.getCachedRecentChats();
      final myEmail = (currentUser?.email ?? '').trim().toLowerCase();
      final sanitizedCache = cached.where((u) {
        final uEmail = u.email.trim().toLowerCase();
        final uId = u.id.trim();
        return uEmail != myEmail &&
            uEmail != 'admin@gmail.com' &&
            uEmail != 'agency@gmail.com' &&
            uId != '1' &&
            uId != '23';
      }).toList();

      if (sanitizedCache.isNotEmpty) {
        AppLogger.info('fetchAgencyUsers: API returned empty. Using ${sanitizedCache.length} sanitized cached users.');
        return sanitizedCache;
      }

      AppLogger.info('fetchAgencyUsers: No assigned users found in API or cache.');
      return [];
    } on NetworkException catch (e) {
      AppLogger.warning('fetchAgencyUsers NetworkException: ${e.message}. Using cached users.');
      final cached = _localStorage.getCachedRecentChats();
      return cached;
    } catch (e) {
      AppLogger.warning('fetchAgencyUsers error: $e. Using cached users.');
      final cached = _localStorage.getCachedRecentChats();
      return cached;
    }
  }

  @override
  Future<bool> createUser(String name, String email, String mob, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'action': 'create_user',
          'name': name,
          'email': email,
          'mob': mob,
          'password': password,
        },
      );
      final data = response.data;
      return data is Map<String, dynamic> && data['success'] == true;
    } catch (e) {
      AppLogger.error('createUser error: $e');
      return false;
    }
  }

  @override
  Future<bool> updateUser(int id, String name) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'action': 'update_user',
          'id': id,
          'name': name,
        },
      );
      final data = response.data;
      return data is Map<String, dynamic> && data['success'] == true;
    } catch (e) {
      AppLogger.error('updateUser error: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteUser(int id) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'action': 'delete_user',
          'id': id,
        },
      );
      final data = response.data;
      return data is Map<String, dynamic> && data['success'] == true;
    } catch (e) {
      AppLogger.error('deleteUser error: $e');
      return false;
    }
  }
}
