import 'package:shared_preferences/shared_preferences.dart';

class RecentSearches {
  static const _key = 'recent_searches';
  static const _maxItems = 10;

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> add(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_key) ?? [];
    searches.remove(query);
    searches.insert(0, query);
    if (searches.length > _maxItems) {
      searches.removeRange(_maxItems, searches.length);
    }
    await prefs.setStringList(_key, searches);
  }

  static Future<void> remove(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_key) ?? [];
    searches.remove(query);
    await prefs.setStringList(_key, searches);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
