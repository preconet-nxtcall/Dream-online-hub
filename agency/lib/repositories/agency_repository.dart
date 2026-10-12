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

      final primaryAgencyId = currentUser?.id ?? '';
      final cleanPrimaryAgencyId = primaryAgencyId.replaceAll(RegExp(r'\D'), '');

      List<dynamic> rawList = [];

      // Helper to extract list from diverse response structures
      List<dynamic> extractListFromResponse(dynamic resData) {
        if (resData is List) return resData;
        if (resData is Map<String, dynamic>) {
          if (resData['data'] is List) return resData['data'] as List;
          if (resData['users'] is List) return resData['users'] as List;
          if (resData['clients'] is List) return resData['clients'] as List;
          if (resData['assigned_users'] is List) return resData['assigned_users'] as List;
          if (resData['rows'] is List) return resData['rows'] as List;
          if (resData['list'] is List) return resData['list'] as List;
        }
        return [];
      }

      // 1. Fetch via 'read_users'
      try {
        final res = await _apiClient.post(
          ApiEndpoints.login,
          data: {'action': 'read_users'},
        );
        final list = extractListFromResponse(res.data);
        if (list.isNotEmpty) {
          rawList = list;
        }
      } catch (_) {}

      // 2. Fetch via 'get_by_agency_id' / 'agency_users' if empty
      if (rawList.isEmpty && agencyIdSet.isNotEmpty) {
        for (final agId in [cleanPrimaryAgencyId, primaryAgencyId, currentUser?.agencyId ?? '']) {
          if (agId.isEmpty) continue;
          try {
            final res = await _apiClient.post(
              ApiEndpoints.login,
              data: {
                'action': 'get_by_agency_id',
                'agency_id': agId,
              },
            );
            final list = extractListFromResponse(res.data);
            if (list.isNotEmpty) {
              rawList = list;
              break;
            }
          } catch (_) {}
        }
      }

      // 3. Fallback: try 'get_users' or 'get_assigned_users'
      if (rawList.isEmpty && agencyIdSet.isNotEmpty) {
        try {
          final res = await _apiClient.post(
            ApiEndpoints.login,
            data: {
              'action': 'get_assigned_users',
              'agency_id': cleanPrimaryAgencyId,
            },
          );
          final list = extractListFromResponse(res.data);
          if (list.isNotEmpty) {
            rawList = list;
          }
        } catch (_) {}
      }

      // Filter & normalize assigned clients (STRICT: ONLY regular users/clients, NO employees)
      List<dynamic> extractAssignedUsers(List<dynamic> inputList) {
        return inputList.where((item) {
          if (item is! Map<String, dynamic>) return false;

          final roleVal = (item['role'] ?? '').toString().trim().toUpperCase();
          final typeVal = (item['type'] ?? '').toString().trim().toUpperCase();
          final portalVal = (item['portal'] ?? '').toString().trim().toUpperCase();
          final userTypeVal = (item['user_type'] ?? '').toString().trim().toUpperCase();

          // 1. STRICT: Exclude any employee, staff, agent, agency, or admin accounts
          final isStaffOrEmployee = roleVal.contains('EMPLOYEE') ||
              roleVal.contains('STAFF') ||
              roleVal.contains('AGENT') ||
              roleVal.contains('AGENCY') ||
              roleVal.contains('ADMIN') ||
              roleVal.contains('MANAGER') ||
              typeVal.contains('EMPLOYEE') ||
              typeVal.contains('STAFF') ||
              typeVal.contains('AGENT') ||
              typeVal.contains('AGENCY') ||
              typeVal.contains('ADMIN') ||
              typeVal.contains('MANAGER') ||
              portalVal.contains('EMPLOYEE') ||
              portalVal.contains('STAFF') ||
              userTypeVal.contains('EMPLOYEE') ||
              userTypeVal.contains('STAFF') ||
              item['is_employee'] == 1 ||
              item['is_employee'] == '1' ||
              item['is_employee'] == true ||
              item['emp_role'] != null;

          if (isStaffOrEmployee) {
            return false;
          }

          // 2. Accept only standard customer/client roles
          final isClientRole = roleVal == 'USER' ||
              roleVal == 'CLIENT' ||
              roleVal == 'CUSTOMER' ||
              roleVal == 'PLAYER' ||
              roleVal == 'MEMBER' ||
              typeVal == 'USER' ||
              typeVal == 'CLIENT' ||
              typeVal == 'CUSTOMER' ||
              typeVal == 'PLAYER' ||
              typeVal == 'MEMBER' ||
              (roleVal.isEmpty && typeVal.isEmpty);

          if (!isClientRole) {
            return false;
          }

          final itemEmail = (item['email'] ?? '').toString().trim().toLowerCase();
          final itemId = (item['id'] ?? item['user_id'] ?? '').toString().trim();
          final myEmail = (currentUser?.email ?? '').trim().toLowerCase();

          // Exclude Agency's own account and master admin
          if (itemEmail == myEmail ||
              itemEmail == 'admin@gmail.com' ||
              itemEmail == 'agency@gmail.com' ||
              (currentUser != null && itemId == currentUser.id)) {
            return false;
          }

          // Strict agency check: Agency A can ONLY see Agency A records (never Agency B)
          if (agencyIdSet.isNotEmpty && currentUser?.isAdmin != true) {
            final candidateAgencyValues = [
              item['agency_id'],
              item['emp_id'],
              item['agent_id'],
              item['agency_unq_id'],
              item['agencyId'],
              item['assigned_agency'],
              item['assigned_to'],
              item['agency'],
            ];

            bool matched = false;
            for (final cand in candidateAgencyValues) {
              if (cand == null) continue;
              final candStr = cand.toString().trim();
              if (candStr.isEmpty || candStr == '0' || candStr == 'null') continue;
              final candClean = candStr.replaceAll(RegExp(r'\D'), '');

              if (agencyIdSet.contains(candStr) || (candClean.isNotEmpty && agencyIdSet.contains(candClean))) {
                matched = true;
                break;
              }
            }

            if (!matched) return false;
          }

          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            final q = searchQuery.trim().toLowerCase();
            final name  = (item['name']  ?? item['username'] ?? '').toString().toLowerCase();
            final email = (item['email'] ?? '').toString().toLowerCase();
            final mob   = (item['mob']   ?? item['phone'] ?? '').toString().toLowerCase();
            return name.contains(q) || email.contains(q) || mob.contains(q);
          }
          return true;
        }).toList();
      }

      final filtered = extractAssignedUsers(rawList);

      // Apply pagination
      final offset = (page - 1) * limit;
      final paginated = filtered.skip(offset).take(limit).toList();

      List<AgencyUserItem> users = paginated
          .map((item) => AgencyUserItem.fromJson(item as Map<String, dynamic>))
          .toList();

      if (users.isNotEmpty) {
        await _localStorage.saveRecentChats(users);
        AppLogger.info('fetchAgencyUsers: Loaded ${users.length} real assigned users from database.');
      } else {
        AppLogger.info('fetchAgencyUsers: Database returned 0 assigned users for this agency.');
      }

      return users;
    } on NetworkException catch (e) {
      AppLogger.warning('fetchAgencyUsers NetworkException: ${e.message}');
      return [];
    } catch (e) {
      AppLogger.warning('fetchAgencyUsers error: $e');
      return [];
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
