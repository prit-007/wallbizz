class ApiCache {
  static final _cache = <String, _CacheEntry>{};
  static int _accessCount = 0;
  static const _evictionInterval = 50;

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
    _accessCount++;
    if (_accessCount >= _evictionInterval) {
      _evictExpired();
      _accessCount = 0;
    }
  }

  static void invalidate(String key) => _cache.remove(key);

  static void invalidatePrefix(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  static void clear() => _cache.clear();

  static int get size => _cache.length;

  static void _evictExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }
}

class _CacheEntry {
  final String data;
  final DateTime expiresAt;

  _CacheEntry(this.data, Duration ttl) : expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
