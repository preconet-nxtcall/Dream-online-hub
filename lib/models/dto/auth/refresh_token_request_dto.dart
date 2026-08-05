class RefreshTokenRequestDto {
  final String refreshToken;

  const RefreshTokenRequestDto({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {
      'refresh_token': refreshToken,
    };
  }
}
