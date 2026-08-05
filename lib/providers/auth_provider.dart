import 'package:flutter/foundation.dart';
import '../core/errors/exceptions.dart';
import '../models/common/user_model.dart';
import '../repositories/auth_repository.dart';
import '../socket/socket_service.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  late final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthProvider({AuthRepository? authRepository}) {
    _authRepository = authRepository ??
        AuthRepositoryImpl(onSessionExpired: () => handleSessionExpired());
  }

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  bool get isLoading => _status == AuthStatus.authenticating || _status == AuthStatus.initial;

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
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(email, password);
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
      _errorMessage = 'Login failed: ${e.toString()}';
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
