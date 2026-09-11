class ApiCache {
  static final _cache = <String, _CacheEntry>{};

  static String? get(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data;
  }

  static void set(String key, String data, [Duration? ttl]) {
    _cache[key] = _CacheEntry(data, ttl ?? const Duration(minutes: 3));
  }

  static void invalidate(String key) => _cache.remove(key);

  static void invalidatePrefix(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  static void clear() => _cache.clear();
}

class _CacheEntry {
  final String data;
  final DateTime expiresAt;

  _CacheEntry(this.data, Duration ttl) : expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
