import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      AppLogger.warning('SecureStorage write error ($key): $e');
    }
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      AppLogger.warning('SecureStorage read error ($key): $e');
      return null;
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      AppLogger.warning('SecureStorage delete error ($key): $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      AppLogger.warning('SecureStorage clearAll error: $e');
    }
  }

  Future<void> deleteAll() async {
    await clearAll();
  }
}
