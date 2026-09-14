import '../../utils/date_formatter.dart';

class AgencyUserItem {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isOnline;
  final int unreadCount;
  final String? lastMessage;
  final DateTime? lastActiveTime;
  final String? agentId; // The agency's agentId/agency_unq_id (e.g. AGENCY-23)

  AgencyUserItem({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isOnline = false,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastActiveTime,
    this.agentId,
  });

  factory AgencyUserItem.fromJson(Map<String, dynamic> json) {
    final dateVal = json['last_active'] ?? json['lastActiveTime'] ?? json['lastMessageAt'] ?? json['updated_at'];
    final DateTime? parsedDate = dateVal != null ? DateFormatter.parseToLocal(dateVal) : null;

    int unread = 0;
    if (json['unread'] != null) {
      if (json['unread'] is int) {
        unread = json['unread'];
      } else if (json['unread'] is Map) {
        unread = json['unread']['agent'] ?? json['unread']['user'] ?? 0;
      }
    } else {
      unread = json['unread_count'] ?? json['unreadCount'] ?? 0;
    }

    final targetId = (json['userId'] ?? json['user_id'] ?? json['id'] ?? json['_id'] ?? '').toString();
    final targetName = (json['name'] ?? json['username'] ?? json['full_name'] ?? targetId).toString();

    final rawAvatar = json['avatar_url'] ?? json['avatarUrl'] ?? json['avatar'] ?? json['img'];
    String? avatarStr;
    if (rawAvatar != null && rawAvatar.toString().isNotEmpty) {
      final str = rawAvatar.toString();
      if (str.startsWith('http')) {
        avatarStr = str;
      } else {
        avatarStr = 'https://dreamonlinehub.club/uploads/photos/$str';
      }
    }

    return AgencyUserItem(
      id: targetId,
      name: targetName.isEmpty ? 'Agency Client' : targetName,
      email: (json['email'] ?? '').toString(),
      avatarUrl: avatarStr,
      isOnline: json['is_online'] ?? json['isOnline'] ?? json['online'] ?? false,
      unreadCount: unread,
      lastMessage: json['last_message'] ?? json['lastMessage'] ?? json['message'],
      lastActiveTime: parsedDate,
      agentId: (json['agentId'] ?? json['agent_id'] ?? '').toString(),
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
    String? agentId,
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
      agentId: agentId ?? this.agentId,
    );
  }
}
