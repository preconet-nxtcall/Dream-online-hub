import '../models/user/user_profile_model.dart';

abstract class UserRepository {
  Future<UserProfileModel> getUserProfile(String userId);
}

class UserRepositoryImpl implements UserRepository {
  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    throw UnimplementedError();
  }
}
