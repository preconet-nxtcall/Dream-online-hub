class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'agency' or 'user'
  final String? avatarUrl;
  final String? phone;
  final String? agencyId;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.phone,
    this.agencyId,
  });

  // Only AGENCY type accounts access the agency dashboard
  bool get isAgency {
    final r = role.toLowerCase();
    return r == 'agency';
  }
  bool get isUser => role.trim().toUpperCase() == 'USER';
  bool get isAdmin => role.trim().toUpperCase() == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawAvatar = json['avatar_url'] ?? json['avatarUrl'] ?? json['avatar'] ?? json['img'];
    String? avatarStr;
    if (rawAvatar != null && rawAvatar.toString().isNotEmpty) {
      final str = rawAvatar.toString();
      if (str.startsWith('http')) {
        avatarStr = str;
      } else {
        avatarStr = 'https://fairbizcrm.com/uploads/photos/$str';
      }
    }

    String? resolvedAgencyId;
    final agencyCandidates = [
      json['agency_id'],
      json['emp_id'],
      json['agent_id'],
      json['agency_unq_id'],
      json['agencyId'],
    ];
    for (final cand in agencyCandidates) {
      if (cand != null) {
        final str = cand.toString().trim();
        if (str.isNotEmpty && str != 'null' && str != '0') {
          resolvedAgencyId = str;
          break;
        }
      }
    }

    return UserModel(
      id: (json['id'] ?? json['_id'] ?? json['user_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? json['username'] ?? json['fullName'] ?? json['full_name'] ?? '').toString(),
      role: (json['role'] ?? json['type'] ?? 'agency').toString(),
      avatarUrl: avatarStr,
      phone: json['phone'] ?? json['phone_number'] ?? json['phoneNumber'] ?? json['mob'] ?? json['mobile'],
      agencyId: resolvedAgencyId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (phone != null) 'phone': phone,
      if (agencyId != null) 'agency_id': agencyId,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? avatarUrl,
    String? phone,
    String? agencyId,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      agencyId: agencyId ?? this.agencyId,
    );
  }
}
