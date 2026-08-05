class UserProfileModel {
  final String userId;
  final String phoneNumber;
  final String avatarUrl;

  UserProfileModel({
    required this.userId,
    required this.phoneNumber,
    required this.avatarUrl,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['user_id'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
    );
  }
}
