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
    // PHP api.php login returns { success, message, user: { id, name, email, phone, role, avatar } }
    final dynamic userField = json['user'] ?? json['data'];
    final Map<String, dynamic> userMap =
        (userField is Map<String, dynamic>) ? userField : json;

    // Accept token if backend ever adds one, otherwise generate a local session key
    final token = json['access_token'] ??
        json['token'] ??
        json['accessToken'] ??
        'session_${userMap['id'] ?? DateTime.now().millisecondsSinceEpoch}';

    return LoginResponseDto(
      accessToken: token.toString(),
      refreshToken: (json['refresh_token'] ?? json['refreshToken'] ?? '').toString(),
      expiresIn: json['expires_in'] ?? json['expiresIn'] ?? 86400,
      user: userMap,
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
