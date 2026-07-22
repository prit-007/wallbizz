import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/wallpaper.dart';

class HistoryService {
  static const _searchKey = 'search_history';
  static const _recentKey = 'recent_wallpapers';
  static const _maxSearches = 10;
  static const _maxRecent = 20;

  static Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_searchKey);
    return data ?? [];
  }

  static Future<void> addSearchQuery(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_searchKey) ?? [];
    history.remove(query);
    history.insert(0, query);
    if (history.length > _maxSearches) {
      history.removeRange(_maxSearches, history.length);
    }
    await prefs.setStringList(_searchKey, history);
  }

  static Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchKey);
  }

  static Future<void> removeSearchQuery(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_searchKey) ?? [];
    history.remove(query);
    await prefs.setStringList(_searchKey, history);
  }

  static Future<List<Wallpaper>> getRecentWallpapers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_recentKey);
    if (data == null) return [];
    try {
      final list = json.decode(data) as List<dynamic>;
      return list.map((e) => Wallpaper.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addRecentWallpaper(Wallpaper wallpaper) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_recentKey);
    List<Wallpaper> recent = [];
    if (data != null) {
      try {
        final list = json.decode(data) as List<dynamic>;
        recent = list
            .map((e) => Wallpaper.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    recent.removeWhere((w) => w.wallhavenId == wallpaper.wallhavenId);
    recent.insert(0, wallpaper);
    if (recent.length > _maxRecent) {
      recent.removeRange(_maxRecent, recent.length);
    }
    await prefs.setString(
      _recentKey,
      json.encode(recent.map((w) => {
        'id': w.id,
        'wallhaven_id': w.wallhavenId,
        'url_full': w.urlFull,
        'url_thumb': w.urlThumb,
        'resolution': w.resolution,
        'width': w.width,
        'height': w.height,
        'file_size': w.fileSize,
        'primary_color': w.primaryColor,
        'category': w.category,
        'source_query': w.sourceQuery,
        'created_at': w.createdAt.toIso8601String(),
      }).toList()),
    );
  }

  static Future<void> clearRecentWallpapers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
  }
}
