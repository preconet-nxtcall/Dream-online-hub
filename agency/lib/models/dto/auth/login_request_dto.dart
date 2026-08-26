class LoginRequestDto {
  final String action;
  final String email;
  final String password;
  final String? role;
  final Map<String, dynamic>? deviceInfo;

  const LoginRequestDto({
    this.action = 'login',
    required this.email,
    required this.password,
    this.role,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'email': email.trim(),
      'password': password,
      if (role != null) 'role': role,
      if (deviceInfo != null) 'device_info': deviceInfo,
    };
  }
}
