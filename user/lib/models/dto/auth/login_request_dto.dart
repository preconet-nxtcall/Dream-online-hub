class LoginRequestDto {
  final String action;
  final String email;
  final String password;
  final String? phone;
  final String? role;
  final Map<String, dynamic>? deviceInfo;

  const LoginRequestDto({
    this.action = 'login',
    required this.email,
    required this.password,
    this.phone,
    this.role,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    final identifier = email.trim();
    return {
      'action': action,
      'email': identifier,
      'phone': phone?.trim() ?? identifier,
      'username': identifier,
      'password': password,
      if (role != null) 'role': role,
      if (deviceInfo != null) 'device_info': deviceInfo,
    };
  }
}
