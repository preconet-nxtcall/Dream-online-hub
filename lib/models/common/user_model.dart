class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'agency' or 'user'
  final String? avatarUrl;
  final String? phone;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.phone,
  });

  bool get isAgency {
    final r = role.toLowerCase();
    return r == 'agency' || r == 'admin' || r == 'superadmin';
  }
  bool get isUser => !isAgency;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? json['username'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'] ?? json['avatar'],
      phone: json['phone'] ?? json['phone_number'] ?? json['phoneNumber'],
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
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? avatarUrl,
    String? phone,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
    );
  }
}
