class AgencyUserItem {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isOnline;
  final int unreadCount;
  final String? lastMessage;
  final DateTime? lastActiveTime;

  AgencyUserItem({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isOnline = false,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastActiveTime,
  });

  factory AgencyUserItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['last_active'] != null || json['lastActiveTime'] != null || json['updated_at'] != null) {
      final dateVal = json['last_active'] ?? json['lastActiveTime'] ?? json['updated_at'];
      if (dateVal is String) {
        parsedDate = DateTime.tryParse(dateVal);
      } else if (dateVal is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(dateVal);
      }
    }

    return AgencyUserItem(
      id: (json['id'] ?? json['user_id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['username'] ?? json['full_name'] ?? 'Agency User').toString(),
      email: (json['email'] ?? '').toString(),
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'] ?? json['avatar'],
      isOnline: json['is_online'] ?? json['isOnline'] ?? json['online'] ?? false,
      unreadCount: json['unread_count'] ?? json['unreadCount'] ?? json['unread'] ?? 0,
      lastMessage: json['last_message'] ?? json['lastMessage'] ?? json['message'],
      lastActiveTime: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'is_online': isOnline,
      'unread_count': unreadCount,
      if (lastMessage != null) 'last_message': lastMessage,
      if (lastActiveTime != null) 'last_active': lastActiveTime!.toIso8601String(),
    };
  }

  AgencyUserItem copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    bool? isOnline,
    int? unreadCount,
    String? lastMessage,
    DateTime? lastActiveTime,
  }) {
    return AgencyUserItem(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
    );
  }
}
