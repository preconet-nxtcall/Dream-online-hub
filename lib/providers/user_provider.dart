import 'package:flutter/foundation.dart';
import '../models/user/user_profile_model.dart';

class UserProvider extends ChangeNotifier {
  UserProfileModel? _userProfile;
  bool _isLoading = false;

  UserProfileModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    notifyListeners();

    // Fetch user profile logic
    _isLoading = false;
    notifyListeners();
  }
}
