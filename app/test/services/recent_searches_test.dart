import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vivek_app/services/recent_searches.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecentSearches.load', () {
    test('returns empty list when no searches saved', () async {
      final searches = await RecentSearches.load();
      expect(searches, isEmpty);
    });

    test('returns saved searches', () async {
      SharedPreferences.setMockInitialValues({
        'recent_searches': ['cyberpunk', 'nature', 'space'],
      });
      final searches = await RecentSearches.load();
      expect(searches, ['cyberpunk', 'nature', 'space']);
    });
  });

  group('RecentSearches.add', () {
    test('adds new search to front', () async {
      await RecentSearches.add('nature');
      final searches = await RecentSearches.load();
      expect(searches, ['nature']);
    });

    test('moves existing search to front', () async {
      SharedPreferences.setMockInitialValues({
        'recent_searches': ['cyberpunk', 'nature'],
      });
      await RecentSearches.add('nature');
      final searches = await RecentSearches.load();
      expect(searches, ['nature', 'cyberpunk']);
    });

    test('ignores empty queries', () async {
      await RecentSearches.add('');
      await RecentSearches.add('   ');
      final searches = await RecentSearches.load();
      expect(searches, isEmpty);
    });

    test('caps at 10 items', () async {
      SharedPreferences.setMockInitialValues({
        'recent_searches': ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
      });
      await RecentSearches.add('10');
      final searches = await RecentSearches.load();
      expect(searches.length, 10);
      expect(searches.first, '10');
      expect(searches.last, '9');
    });

    test('does not exceed 10 items', () async {
      SharedPreferences.setMockInitialValues({
        'recent_searches': ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
      });
      await RecentSearches.add('11');
      final searches = await RecentSearches.load();
      expect(searches.length, 10);
      expect(searches.first, '11');
      expect(searches.contains('10'), false);
    });
  });

  group('RecentSearches.remove', () {
    test('removes specific search', () async {
      SharedPreferences.setMockInitialValues({
        'recent_searches': ['cyberpunk', 'nature', 'space'],
      });
      await RecentSearches.remove('nature');
      final searches = await RecentSearches.load();
      expect(searches, ['cyberpunk', 'space']);
    });

    test('removing non-existent search is no-op', () async {
      SharedPreferences.setMockInitialValues({
        'recent_searches': ['cyberpunk'],
      });
      await RecentSearches.remove('nature');
      final searches = await RecentSearches.load();
      expect(searches, ['cyberpunk']);
    });
  });

  group('RecentSearches.clear', () {
    test('removes all searches', () async {
      SharedPreferences.setMockInitialValues({
        'recent_searches': ['cyberpunk', 'nature'],
      });
      await RecentSearches.clear();
      final searches = await RecentSearches.load();
      expect(searches, isEmpty);
    });

    test('clear on empty list is no-op', () async {
      await RecentSearches.clear();
      final searches = await RecentSearches.load();
      expect(searches, isEmpty);
    });
  });
}
