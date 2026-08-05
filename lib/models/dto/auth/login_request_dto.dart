class LoginRequestDto {
  final String email;
  final String password;
  final String? role;
  final Map<String, dynamic>? deviceInfo;

  const LoginRequestDto({
    required this.email,
    required this.password,
    this.role,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim(),
      'password': password,
      if (role != null) 'role': role,
      if (deviceInfo != null) 'device_info': deviceInfo,
    };
  }
}
