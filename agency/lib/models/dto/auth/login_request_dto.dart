class LoginRequestDto {
  final String action;
  final String email;
  final String password;
  final String? role;
  final String? portal;
  final Map<String, dynamic>? deviceInfo;

  const LoginRequestDto({
    this.action = 'login',
    required this.email,
    required this.password,
    this.role,
    this.portal,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    final identifier = email.trim();
    return {
      'action': action,
      'email': identifier,
      'mob': identifier,
      'mobile': identifier,
      'username': identifier,
      'user_name': identifier,
      'phone': identifier,
      'password': password,
      if (role != null) 'role': role,
      if (portal != null) 'portal': portal,
      if (deviceInfo != null) 'device_info': deviceInfo,
    };
  }
}
