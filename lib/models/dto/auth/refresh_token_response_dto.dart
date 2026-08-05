class RefreshTokenResponseDto {
  final String accessToken;
  final String? refreshToken;
  final int expiresIn;

  const RefreshTokenResponseDto({
    required this.accessToken,
    this.refreshToken,
    required this.expiresIn,
  });

  factory RefreshTokenResponseDto.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponseDto(
      accessToken: (json['access_token'] ?? json['token'] ?? json['accessToken'] ?? '').toString(),
      refreshToken: json['refresh_token'] ?? json['refreshToken'],
      expiresIn: json['expires_in'] ?? json['expiresIn'] ?? 3600,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      if (refreshToken != null) 'refresh_token': refreshToken,
      'expires_in': expiresIn,
    };
  }
}
