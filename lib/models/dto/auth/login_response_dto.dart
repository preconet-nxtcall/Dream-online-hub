class LoginResponseDto {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final Map<String, dynamic> user;

  const LoginResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      accessToken: (json['access_token'] ?? json['token'] ?? json['accessToken'] ?? '').toString(),
      refreshToken: (json['refresh_token'] ?? json['refreshToken'] ?? '').toString(),
      expiresIn: json['expires_in'] ?? json['expiresIn'] ?? 3600,
      user: json['user'] is Map<String, dynamic> ? json['user'] : json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'user': user,
    };
  }
}
