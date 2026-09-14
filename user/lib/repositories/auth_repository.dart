import '../core/constants/api_endpoints.dart';
import '../core/constants/storage_keys.dart';
import '../core/errors/exceptions.dart';
import '../models/common/user_model.dart';
import '../models/dto/auth/login_request_dto.dart';
import '../models/dto/auth/login_response_dto.dart';
import '../network/api_client.dart';
import '../storage/local_storage_repository.dart';
import '../storage/secure_storage_service.dart';
import '../utils/logger.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password, {String portalType = 'agency'});
  Future<UserModel> register(String fullName, String email, String phone, String password);
  Future<Map<String, dynamic>> sendOtp(String phone);
  Future<bool> verifyOtp(String phone, String otp);
  Future<UserModel> updateUser({
    required String id,
    required String name,
    required String email,
    required String phone,
  });
  Future<bool> updatePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<bool> deleteUser({required String id});
  Future<UserModel?> getProfile();
  Future<void> logout();
  Future<String?> getStoredToken();
  Future<bool> hasValidToken();
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final LocalStorageRepository _localStorage;

  AuthRepositoryImpl({
    ApiClient? apiClient,
    SecureStorageService? secureStorage,
    LocalStorageRepository? localStorage,
    Function()? onSessionExpired,
  })  : _apiClient = apiClient ?? ApiClient(onSessionExpired: onSessionExpired),
        _secureStorage = secureStorage ?? SecureStorageService(),
        _localStorage = localStorage ?? LocalStorageRepositoryImpl();

  @override
  Future<UserModel> login(String email, String password, {String portalType = 'agency'}) async {
    final loginDto = LoginRequestDto(action: 'login', email: email, password: password);

    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: loginDto.toJson(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('success') && data['success'] == false) {
          throw ServerException(
            message: data['message']?.toString() ?? 'Invalid credentials.',
            statusCode: 401,
          );
        }
      }

      // PHP returns: { success, message, user: { id, name, email, phone, role, avatar } }
      // LoginResponseDto.fromJson handles the nested 'user' key correctly.
      final Map<String, dynamic> responseData =
          (data is Map<String, dynamic>) ? data : {};

      final loginResponseDto = LoginResponseDto.fromJson(responseData);
      final user = UserModel.fromJson(loginResponseDto.user);

      final roleUpper = user.role.trim().toUpperCase();

      // Agency portal: strictly allow only AGENCY type — block USER and ADMIN
      if (portalType == 'agency' && roleUpper != 'AGENCY') {
        throw ServerException(
          message: roleUpper == 'USER'
              ? 'This is the Agency Portal. Please use the User Login instead.'
              : 'Access restricted. Only Agency accounts can log in here.',
          statusCode: 403,
        );
      }

      // User portal: strictly allow only USER type — block AGENCY and ADMIN
      if (portalType == 'user' && roleUpper != 'USER') {
        throw ServerException(
          message: roleUpper == 'AGENCY'
              ? 'This is the User Portal. Please use the Agency Login instead.'
              : 'Access restricted. Only User accounts can log in here.',
          statusCode: 403,
        );
      }

      // Persist session — PHP doesn't issue tokens so we store the generated session key
      try {
        final rawUserAgency = (user.agencyId != null && user.agencyId!.isNotEmpty) ? user.agencyId! : 'ADMIN-1';
        final agentIdVal = user.isAgency
            ? (user.id.startsWith('AGENCY-') ? user.id : 'AGENCY-${user.id}')
            : (rawUserAgency.startsWith('AGENCY-') || rawUserAgency.contains('@') ? rawUserAgency : 'AGENCY-$rawUserAgency');
        await Future.wait([
          if (loginResponseDto.accessToken.isNotEmpty)
            _secureStorage.write(StorageKeys.authToken, loginResponseDto.accessToken),
          _secureStorage.write(StorageKeys.userRole, user.role),
          _secureStorage.write(StorageKeys.userId, user.id),
          if (user.email.isNotEmpty)
            _secureStorage.write(StorageKeys.chatEmailId, user.email),
          if (agentIdVal.isNotEmpty)
            _secureStorage.write(StorageKeys.chatAgentId, agentIdVal),
          _localStorage.saveTokens(
            accessToken: loginResponseDto.accessToken,
            refreshToken: '',
          ),
          _localStorage.saveUser(user),
        ]);
      } catch (e) {
        AppLogger.warning('Background storage persistence error: $e');
      }

      return user;
    } on NetworkException catch (e) {
      AppLogger.error('Login NetworkException: ${e.message} (status: ${e.statusCode})');
      if (e.statusCode != null) {
        throw ServerException(message: e.message, statusCode: e.statusCode);
      }
      throw ServerException(
        message: 'Network error. Please check your internet connection and try again.',
        statusCode: 503,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      AppLogger.error('Login error: $e');
      throw ServerException(message: 'Unexpected login error. Please try again.');
    }
  }

  @override
  Future<UserModel> register(String fullName, String email, String phone, String password) async {
    // PHP api.php does not have a 'register' action.
    // We use the 'create_user' action instead (inserts with type='USER').
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register, // same api.php file
        data: {
          'action': 'create_user',
          'name': fullName,
          'email': email,
          'mob': phone,
          'password': password,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('success') && data['success'] == false) {
        throw ServerException(
          message: data['message']?.toString() ?? 'Registration failed',
          statusCode: 400,
        );
      }

      // PHP create_user returns { success, message, id } — build a minimal UserModel
      final newId = (data is Map<String, dynamic>)
          ? (data['id'] ?? data['user_id'] ?? '').toString()
          : '';

      final user = UserModel(
        id: newId,
        name: fullName,
        email: email,
        role: 'USER',
        phone: phone,
      );

      // Generate a local session key (PHP has no token for create_user)
      final sessionToken = 'session_${newId}_${DateTime.now().millisecondsSinceEpoch}';

      try {
        await Future.wait([
          _secureStorage.write(StorageKeys.authToken, sessionToken),
          _secureStorage.write(StorageKeys.userRole, user.role),
          _secureStorage.write(StorageKeys.userId, user.id),
          _localStorage.saveTokens(accessToken: sessionToken, refreshToken: ''),
          _localStorage.saveUser(user),
        ]);
      } catch (e) {
        AppLogger.warning('Background storage persistence error: $e');
      }

      return user;
    } on NetworkException catch (e) {
      AppLogger.error('Register NetworkException: ${e.message} (status: ${e.statusCode})');
      if (e.statusCode != null) {
        throw ServerException(message: e.message, statusCode: e.statusCode);
      }
      throw ServerException(
        message: 'Network error. Please check your internet connection and try again.',
        statusCode: 503,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      AppLogger.error('Register error: $e');
      throw ServerException(message: 'Registration failed. Please try again.');
    }
  }

  @override
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'action': 'send_otp',
          'phone': cleanPhone,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final successVal = data['success'];
        final statusVal = data['status']?.toString().toLowerCase();
        if (successVal == false || successVal == 'false' || successVal == 0 || statusVal == 'error' || statusVal == 'failed') {
          throw ServerException(
            message: data['message']?.toString() ?? 'Failed to send OTP.',
            statusCode: 400,
          );
        }
        return data;
      }
      throw ServerException(message: 'Invalid response format from server.');
    } on NetworkException catch (e) {
      AppLogger.error('sendOtp NetworkException: ${e.message} (status: ${e.statusCode})');
      if (e.statusCode != null) {
        throw ServerException(message: e.message, statusCode: e.statusCode);
      }
      throw ServerException(
        message: 'Network error. Please check your internet connection and try again.',
        statusCode: 503,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      AppLogger.error('sendOtp error: $e');
      throw ServerException(message: 'Failed to send OTP. Please try again.');
    }
  }

  @override
  Future<bool> verifyOtp(String phone, String otp) async {
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final cleanOtp = otp.trim();
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'action': 'verify_otp',
          'phone': cleanPhone,
          'otp': cleanOtp,
          'code': cleanOtp,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final successVal = data['success'];
        final statusVal = data['status']?.toString().toLowerCase();
        if (successVal == false || successVal == 'false' || successVal == 0 || statusVal == 'error' || statusVal == 'failed') {
          throw ServerException(
            message: data['message']?.toString() ?? 'Invalid OTP code. Please try again.',
            statusCode: 400,
          );
        }
        return true;
      }
      throw ServerException(message: 'Invalid response format from server.');
    } on NetworkException catch (e) {
      AppLogger.error('verifyOtp NetworkException: ${e.message} (status: ${e.statusCode})');
      if (e.statusCode != null) {
        throw ServerException(message: e.message, statusCode: e.statusCode);
      }
      throw ServerException(
        message: 'Network error. Please check your internet connection and try again.',
        statusCode: 503,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      AppLogger.error('verifyOtp error: $e');
      throw ServerException(message: 'OTP verification failed. Please try again.');
    }
  }

  @override
  Future<UserModel> updateUser({
    required String id,
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final numericId = int.tryParse(id.replaceAll(RegExp(r'\D'), '')) ?? id;
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'action': 'update_user',
          'id': numericId,
          'name': name,
          'email': email,
          'mob': phone,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == false) {
        throw ServerException(
          message: data['message']?.toString() ?? 'Failed to update user profile.',
          statusCode: 400,
        );
      }

      final existing = getCachedUser();
      final updatedUser = UserModel(
        id: id,
        name: name,
        email: email,
        phone: phone,
        role: existing?.role ?? 'USER',
        agencyId: existing?.agencyId,
        avatarUrl: existing?.avatarUrl,
      );

      await _localStorage.saveUser(updatedUser);
      return updatedUser;
    } on NetworkException catch (e) {
      throw ServerException(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to update profile. Please try again.');
    }
  }

  @override
  Future<bool> updatePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final currentUser = getCachedUser();
      int? userId;
      if (currentUser?.id != null && currentUser!.id.isNotEmpty) {
        final digitsOnly = currentUser.id.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.isNotEmpty) {
          userId = int.tryParse(digitsOnly);
        }
      }
      if (userId == null) {
        final storedUserId = await _secureStorage.read(StorageKeys.userId);
        if (storedUserId != null && storedUserId.isNotEmpty) {
          final digitsOnly = storedUserId.replaceAll(RegExp(r'\D'), '');
          if (digitsOnly.isNotEmpty) {
            userId = int.tryParse(digitsOnly);
          }
        }
      }
      if (userId == null) {
        throw ServerException(message: 'User session not found. Please log in again.');
      }

      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'action': 'update_password',
          'user_id': userId,
          'old_password': oldPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == false) {
        throw ServerException(
          message: data['message']?.toString() ?? 'Failed to update password.',
          statusCode: 400,
        );
      }

      return true;
    } on NetworkException catch (e) {
      throw ServerException(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to update password. Please try again.');
    }
  }

  @override
  Future<bool> deleteUser({required String id}) async {
    try {
      final numericId = int.tryParse(id.replaceAll(RegExp(r'\D'), '')) ?? id;
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'action': 'delete_user',
          'id': numericId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == false) {
        throw ServerException(
          message: data['message']?.toString() ?? 'Failed to delete user account.',
          statusCode: 400,
        );
      }

      await logout();
      return true;
    } on NetworkException catch (e) {
      throw ServerException(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to delete account. Please try again.');
    }
  }



  @override
  Future<UserModel?> getProfile() async {
    // PHP api.php has no 'profile' action — return from local cache only.
    AppLogger.info('getProfile: PHP has no profile endpoint. Returning cached user.');
    return getCachedUser();
  }

  UserModel? getCachedUser() {
    final hiveUser = _localStorage.getUser();
    if (hiveUser != null) return hiveUser;

    return null;
  }

  @override
  Future<void> logout() async {
    // PHP api.php has no 'logout' action — just clear local storage.
    AppLogger.info('logout: Clearing local session (PHP has no logout endpoint).');
    await _secureStorage.delete(StorageKeys.authToken);
    await _secureStorage.delete(StorageKeys.refreshToken);
    await _secureStorage.delete(StorageKeys.userId);
    await _secureStorage.delete(StorageKeys.userRole);
    await _secureStorage.delete(StorageKeys.chatToken);
    await _secureStorage.delete(StorageKeys.chatEmailId);
    await _secureStorage.delete(StorageKeys.chatAgentId);
    await _localStorage.clearAuthData();
  }

  @override
  Future<String?> getStoredToken() async {
    final secureToken = await _secureStorage.read(StorageKeys.authToken);
    if (secureToken != null && secureToken.isNotEmpty) return secureToken;
    return _localStorage.getAccessToken();
  }

  @override
  Future<bool> hasValidToken() async {
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }
}
