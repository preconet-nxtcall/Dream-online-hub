import '../../agency/agency_user_item_model.dart';

class AgencyUsersResponseDto {
  final List<AgencyUserItem> users;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  const AgencyUsersResponseDto({
    required this.users,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory AgencyUsersResponseDto.fromJson(Map<String, dynamic> json) {
    List<dynamic> rawList = [];
    if (json['users'] is List) {
      rawList = json['users'];
    } else if (json['data'] is List) {
      rawList = json['data'];
    } else if (json['items'] is List) {
      rawList = json['items'];
    }

    final parsedUsers = rawList
        .map((item) => AgencyUserItem.fromJson(item is Map<String, dynamic> ? item : {}))
        .toList();

    final int totalCount = json['total'] ?? parsedUsers.length;
    final int currentPage = json['page'] ?? 1;
    final int pageSize = json['limit'] ?? 10;
    final bool moreAvailable = json['has_more'] ?? json['hasMore'] ?? (parsedUsers.length >= pageSize);

    return AgencyUsersResponseDto(
      users: parsedUsers,
      total: totalCount,
      page: currentPage,
      limit: pageSize,
      hasMore: moreAvailable,
    );
  }
}
