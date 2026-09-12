import 'package:flutter_test/flutter_test.dart';
import 'package:wallbizz/services/api_cache.dart';

void main() {
  setUp(() {
    ApiCache.clear();
  });

  group('ApiCache.get', () {
    test('returns null for missing key', () {
      expect(ApiCache.get('nonexistent'), isNull);
    });

    test('returns cached data for existing key', () {
      ApiCache.set('test-key', '{"data": "value"}');
      expect(ApiCache.get('test-key'), '{"data": "value"}');
    });

    test('returns null for expired entry', () async {
      ApiCache.set('short-key', 'data', Duration(milliseconds: 1));
      await Future.delayed(const Duration(milliseconds: 10));
      expect(ApiCache.get('short-key'), isNull);
    });

    test('returns data before expiry', () {
      ApiCache.set('valid-key', 'data', const Duration(minutes: 5));
      expect(ApiCache.get('valid-key'), 'data');
    });
  });

  group('ApiCache.set', () {
    test('stores data with default TTL', () {
      ApiCache.set('key1', 'value1');
      expect(ApiCache.get('key1'), 'value1');
    });

    test('overwrites existing key', () {
      ApiCache.set('key1', 'old');
      ApiCache.set('key1', 'new');
      expect(ApiCache.get('key1'), 'new');
    });

    test('multiple keys coexist', () {
      ApiCache.set('a', '1');
      ApiCache.set('b', '2');
      expect(ApiCache.get('a'), '1');
      expect(ApiCache.get('b'), '2');
    });
  });

  group('ApiCache.invalidate', () {
    test('removes specific key', () {
      ApiCache.set('a', '1');
      ApiCache.set('b', '2');
      ApiCache.invalidate('a');
      expect(ApiCache.get('a'), isNull);
      expect(ApiCache.get('b'), '2');
    });

    test('invalidating missing key is no-op', () {
      ApiCache.set('a', '1');
      ApiCache.invalidate('nonexistent');
      expect(ApiCache.get('a'), '1');
    });
  });

  group('ApiCache.invalidatePrefix', () {
    test('removes all keys with matching prefix', () {
      ApiCache.set('wishlist:user1', 'data1');
      ApiCache.set('wishlist:user1:extra', 'data2');
      ApiCache.set('moodboards:user1', 'data3');
      ApiCache.invalidatePrefix('wishlist:user1');
      expect(ApiCache.get('wishlist:user1'), isNull);
      expect(ApiCache.get('wishlist:user1:extra'), isNull);
      expect(ApiCache.get('moodboards:user1'), 'data3');
    });

    test('removes nothing if no keys match', () {
      ApiCache.set('a', '1');
      ApiCache.invalidatePrefix('xyz');
      expect(ApiCache.get('a'), '1');
    });
  });

  group('ApiCache.clear', () {
    test('removes all entries', () {
      ApiCache.set('a', '1');
      ApiCache.set('b', '2');
      ApiCache.set('c', '3');
      ApiCache.clear();
      expect(ApiCache.get('a'), isNull);
      expect(ApiCache.get('b'), isNull);
      expect(ApiCache.get('c'), isNull);
    });

    test('clear on empty cache is no-op', () {
      ApiCache.clear();
      expect(ApiCache.get('anything'), isNull);
    });
  });
}
