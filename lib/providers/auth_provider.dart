import 'package:flutter/foundation.dart';
import '../core/errors/exceptions.dart';
import '../models/common/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/chat_repository.dart';
import '../socket/socket_service.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  late final AuthRepository _authRepository;
  late final ChatRepository _chatRepository;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthProvider({AuthRepository? authRepository, ChatRepository? chatRepository}) {
    _authRepository = authRepository ??
        AuthRepositoryImpl(onSessionExpired: () => handleSessionExpired());
    _chatRepository = chatRepository ?? ChatRepositoryImpl();
  }

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  // Only show loading spinner during active auth operations, not on initial startup
  bool get isLoading => _status == AuthStatus.authenticating;

  /// Check token & auto login on application startup
  Future<bool> checkAutoLogin() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final hasToken = await _authRepository.hasValidToken();
      if (!hasToken) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final profile = await _authRepository.getProfile();
      if (profile != null) {
        _currentUser = profile;
        _status = AuthStatus.authenticated;
        SocketService.instance.connect();
        notifyListeners();
        return true;
      } else {
        await _authRepository.logout();
        SocketService.instance.disconnect();
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      await _authRepository.logout();
      SocketService.instance.disconnect();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Perform user login
  Future<bool> login(String email, String password, {String portalType = 'agency'}) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(email, password, portalType: portalType);
      _currentUser = user;
      _status = AuthStatus.authenticated;
      notifyListeners();

      // Auto-authenticate with the Node.js chat server using same credentials.
      // This is non-blocking — chat server failure does not block PHP login.
      _loginToChatServerSilently(email, password);

      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Silently login to the Node.js chat server after PHP login succeeds.
  void _loginToChatServerSilently(String email, String password) {
    _chatRepository.loginToChat(email, password).then((_) {
      // Connect Socket.IO after we have the chat JWT
      SocketService.instance.connect();
    }).catchError((e) {
      // Non-fatal — chat server may not be running
      debugPrint('[AuthProvider] Chat server login skipped: $e');
    });
  }

  /// Perform user registration
  Future<bool> register(String fullName, String email, String phone, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.register(fullName, email, phone, password);
      _currentUser = user;
      _status = AuthStatus.authenticated;
      SocketService.instance.connect();
      notifyListeners();
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Perform user logout
  Future<void> logout() async {
    await _authRepository.logout();
    SocketService.instance.disconnect();
    _currentUser = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Perform user profile update
  Future<bool> updateUserProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    if (_currentUser == null) return false;
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _authRepository.updateUser(
        id: _currentUser!.id,
        name: name,
        email: email,
        phone: phone,
      );
      _currentUser = updated;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update user profile: ${e.toString()}';
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    }
  }

  /// Perform password update
  Future<bool> updatePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authRepository.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      notifyListeners();
      return success;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update password: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Perform user deletion
  Future<bool> deleteUserAccount() async {
    if (_currentUser == null) return false;
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authRepository.deleteUser(id: _currentUser!.id);
      SocketService.instance.disconnect();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return success;
    } on ServerException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete account: ${e.toString()}';
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    }
  }

  /// Called when API interceptor catches 401 Unauthorized
  Future<void> handleSessionExpired() async {
    await _authRepository.logout();
    SocketService.instance.disconnect();
    _currentUser = null;
    _errorMessage = 'Session expired. Please log in again.';
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = _currentUser != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
