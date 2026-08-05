import '../core/constants/api_endpoints.dart';
import '../core/errors/exceptions.dart';
import '../models/agency/agency_model.dart';
import '../models/agency/agency_user_item_model.dart';
import '../models/dto/agency/agency_users_request_dto.dart';
import '../models/dto/agency/agency_users_response_dto.dart';
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
    try {
      final response = await _apiClient.get('${ApiEndpoints.agencyDashboard}/$agencyId');
      final data = response.data;
      return AgencyModel.fromJson(data is Map<String, dynamic> ? data : {});
    } on NetworkException catch (e) {
      throw ServerException(message: e.message, statusCode: e.statusCode);
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
    final requestDto = AgencyUsersRequestDto(
      page: page,
      limit: limit,
      searchQuery: searchQuery,
    );

    try {
      final response = await _apiClient.get(
        '/agency/users',
        queryParameters: requestDto.toQueryParameters(),
      );

      final data = response.data;
      List<AgencyUserItem> users = [];

      if (data is Map<String, dynamic>) {
        final responseDto = AgencyUsersResponseDto.fromJson(data);
        if (responseDto.users.isNotEmpty) {
          users = responseDto.users;
        }
      } else if (data is List) {
        users = data
            .map((item) => AgencyUserItem.fromJson(item is Map<String, dynamic> ? item : {}))
            .toList();
      }

      if (users.isNotEmpty) {
        await _localStorage.saveRecentChats(users);
        return users;
      }

      final demoUsers = _generateDemoUsers(page: page, limit: limit, query: searchQuery);
      await _localStorage.saveRecentChats(demoUsers);
      return demoUsers;
    } on NetworkException catch (e) {
      AppLogger.warning('fetchAgencyUsers NetworkException: ${e.message}. Using cached or fallback users.');
    } catch (e) {
      AppLogger.warning('fetchAgencyUsers error: $e. Using cached or fallback users.');
    }

    final cached = _localStorage.getCachedRecentChats();
    if (cached.isNotEmpty) {
      return cached;
    }

    final fallback = _generateDemoUsers(page: page, limit: limit, query: searchQuery);
    await _localStorage.saveRecentChats(fallback);
    return fallback;
  }

  /// Demo fallback generator if backend endpoint is not reachable
  List<AgencyUserItem> _generateDemoUsers({required int page, required int limit, String? query}) {
    if (page > 3) return []; // End of pagination after 3 pages in demo mode

    final now = DateTime.now();
    final allDemoUsers = [
      AgencyUserItem(
        id: 'usr_1',
        name: 'Sarah Connor',
        email: 'sarah.connor@example.com',
        isOnline: true,
        unreadCount: 3,
        lastMessage: 'Can we schedule a call regarding project status?',
        lastActiveTime: now.subtract(const Duration(minutes: 2)),
      ),
      AgencyUserItem(
        id: 'usr_2',
        name: 'Michael Vance',
        email: 'm.vance@techcorp.io',
        isOnline: true,
        unreadCount: 0,
        lastMessage: 'All documents have been uploaded successfully.',
        lastActiveTime: now.subtract(const Duration(minutes: 15)),
      ),
      AgencyUserItem(
        id: 'usr_3',
        name: 'Elena Rostova',
        email: 'elena.rostova@design.com',
        isOnline: false,
        unreadCount: 1,
        lastMessage: 'Please review the updated UI mockups when ready.',
        lastActiveTime: now.subtract(const Duration(hours: 1)),
      ),
      AgencyUserItem(
        id: 'usr_4',
        name: 'David Miller',
        email: 'david.m@solutions.org',
        isOnline: false,
        unreadCount: 0,
        lastMessage: 'Thanks for the quick response!',
        lastActiveTime: now.subtract(const Duration(hours: 4)),
      ),
      AgencyUserItem(
        id: 'usr_5',
        name: 'Amara Patel',
        email: 'amara.patel@global.com',
        isOnline: true,
        unreadCount: 5,
        lastMessage: 'Urgent: Requesting update on service ticket #1042',
        lastActiveTime: now.subtract(const Duration(minutes: 1)),
      ),
      AgencyUserItem(
        id: 'usr_6',
        name: 'James Reynolds',
        email: 'jreynolds@enterprise.co',
        isOnline: false,
        unreadCount: 0,
        lastMessage: 'Contract signed and returned.',
        lastActiveTime: now.subtract(const Duration(days: 1)),
      ),
    ];

    var filtered = allDemoUsers;
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      filtered = allDemoUsers
          .where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
          .toList();
    }

    final startIndex = (page - 1) * limit;
    if (startIndex >= filtered.length) return [];
    final endIndex = (startIndex + limit) > filtered.length ? filtered.length : startIndex + limit;

    return filtered.sublist(startIndex, endIndex);
  }
}
