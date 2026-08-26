import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';

abstract class LocalStorageService {
  Future<void> init({String? customPath});
  Box? get authBox;
  Box? get chatsBox;
  Box? get settingsBox;
  Box? get offlineQueueBox;
  Box? get unreadBox;
  Future<void> clearAllBoxes();
}

class HiveLocalStorageService implements LocalStorageService {
  static const String authBoxName = 'auth_box';
  static const String chatsBoxName = 'chats_box';
  static const String settingsBoxName = 'settings_box';
  static const String offlineQueueBoxName = 'offline_queue_box';
  static const String unreadBoxName = 'unread_box';

  Box? _authBox;
  Box? _chatsBox;
  Box? _settingsBox;
  Box? _offlineQueueBox;
  Box? _unreadBox;

  @override
  Box? get authBox => _authBox ?? (Hive.isBoxOpen(authBoxName) ? Hive.box(authBoxName) : null);
  @override
  Box? get chatsBox => _chatsBox ?? (Hive.isBoxOpen(chatsBoxName) ? Hive.box(chatsBoxName) : null);
  @override
  Box? get settingsBox => _settingsBox ?? (Hive.isBoxOpen(settingsBoxName) ? Hive.box(settingsBoxName) : null);
  @override
  Box? get offlineQueueBox => _offlineQueueBox ?? (Hive.isBoxOpen(offlineQueueBoxName) ? Hive.box(offlineQueueBoxName) : null);
  @override
  Box? get unreadBox => _unreadBox ?? (Hive.isBoxOpen(unreadBoxName) ? Hive.box(unreadBoxName) : null);

  @override
  Future<void> init({String? customPath}) async {
    try {
      if (customPath != null && customPath.isNotEmpty) {
        Hive.init(customPath);
      } else {
        await Hive.initFlutter();
      }
      _authBox = await _openBoxSafely(authBoxName);
      _chatsBox = await _openBoxSafely(chatsBoxName);
      _settingsBox = await _openBoxSafely(settingsBoxName);
      _offlineQueueBox = await _openBoxSafely(offlineQueueBoxName);
      _unreadBox = await _openBoxSafely(unreadBoxName);
      AppLogger.info('Hive LocalStorageService initialized successfully!');
    } catch (e) {
      AppLogger.error('Error initializing Hive LocalStorageService: $e');
    }
  }

  Future<Box?> _openBoxSafely(String boxName) async {
    try {
      return await Hive.openBox(boxName);
    } catch (e) {
      AppLogger.warning('Box $boxName failed to open/corrupted ($e). Recovering box...');
      try {
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox(boxName);
      } catch (e2) {
        AppLogger.error('Failed to recover box $boxName: $e2');
        return null;
      }
    }
  }

  @override
  Future<void> clearAllBoxes() async {
    await authBox?.clear();
    await chatsBox?.clear();
    await settingsBox?.clear();
    await offlineQueueBox?.clear();
    await unreadBox?.clear();
  }
}
