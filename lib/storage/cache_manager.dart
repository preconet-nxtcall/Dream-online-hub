class CacheManager {
  final Map<String, dynamic> _memoryCache = {};

  void set(String key, dynamic value) {
    _memoryCache[key] = value;
  }

  dynamic get(String key) {
    return _memoryCache[key];
  }

  void remove(String key) {
    _memoryCache.remove(key);
  }

  void clear() {
    _memoryCache.clear();
  }
}
