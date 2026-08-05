class AgencyUsersRequestDto {
  final int page;
  final int limit;
  final String? searchQuery;
  final String? filter;

  const AgencyUsersRequestDto({
    required this.page,
    required this.limit,
    this.searchQuery,
    this.filter,
  });

  Map<String, dynamic> toQueryParameters() {
    return {
      'page': page,
      'limit': limit,
      if (searchQuery != null && searchQuery!.isNotEmpty) 'query': searchQuery,
      if (filter != null && filter!.isNotEmpty) 'filter': filter,
    };
  }
}
