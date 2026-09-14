import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallbizz/models/wallpaper.dart';
import 'package:wallbizz/services/history_service.dart';

Wallpaper _makeWallpaper({
  String id = 'uuid-1',
  String wallhavenId = 'abc123',
}) {
  return Wallpaper(
    id: id,
    wallhavenId: wallhavenId,
    urlFull: 'https://w.wallhaven.cc/full/ab/wallhaven-$wallhavenId.jpg',
    urlThumb: 'https://th.wallhaven.cc/small/ab/$wallhavenId.jpg',
    resolution: '1920x1080',
    width: 1920,
    height: 1080,
    fileSize: 2000000,
    primaryColor: '#1a1a1a',
    category: 'general',
    sourceQuery: 'trending',
    createdAt: DateTime(2024, 6, 15),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('getSearchHistory', () {
    test('returns empty list when no data', () async {
      final history = await HistoryService.getSearchHistory();
      expect(history, isEmpty);
    });

    test('returns existing history', () async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['cyberpunk', 'nature'],
      });
      final history = await HistoryService.getSearchHistory();
      expect(history, ['cyberpunk', 'nature']);
    });
  });

  group('addSearchQuery', () {
    test('adds query to front of empty list', () async {
      await HistoryService.addSearchQuery('nature');
      final history = await HistoryService.getSearchHistory();
      expect(history, ['nature']);
    });

    test('adds new query to front', () async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['cyberpunk'],
      });
      await HistoryService.addSearchQuery('nature');
      final history = await HistoryService.getSearchHistory();
      expect(history, ['nature', 'cyberpunk']);
    });

    test('moves existing query to front', () async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['cyberpunk', 'nature', 'space'],
      });
      await HistoryService.addSearchQuery('nature');
      final history = await HistoryService.getSearchHistory();
      expect(history, ['nature', 'cyberpunk', 'space']);
    });

    test('caps at 10 items', () async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
      });
      await HistoryService.addSearchQuery('10');
      final history = await HistoryService.getSearchHistory();
      expect(history.length, 10);
      expect(history.first, '10');
      expect(history.last, '9');
    });

    test('does not exceed 10 items when already full', () async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
      });
      await HistoryService.addSearchQuery('11');
      final history = await HistoryService.getSearchHistory();
      expect(history.length, 10);
      expect(history.first, '11');
      expect(history.contains('10'), isFalse);
    });

    test('handles empty string query', () async {
      await HistoryService.addSearchQuery('');
      final history = await HistoryService.getSearchHistory();
      expect(history, ['']);
    });
  });

  group('removeSearchQuery', () {
    test('removes specific query', () async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['cyberpunk', 'nature', 'space'],
      });
      await HistoryService.removeSearchQuery('nature');
      final history = await HistoryService.getSearchHistory();
      expect(history, ['cyberpunk', 'space']);
    });

    test('removing non-existent query is no-op', () async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['cyberpunk'],
      });
      await HistoryService.removeSearchQuery('nature');
      final history = await HistoryService.getSearchHistory();
      expect(history, ['cyberpunk']);
    });
  });

  group('clearSearchHistory', () {
    test('clears all history', () async {
      SharedPreferences.setMockInitialValues({
        'search_history': ['cyberpunk', 'nature'],
      });
      await HistoryService.clearSearchHistory();
      final history = await HistoryService.getSearchHistory();
      expect(history, isEmpty);
    });

    test('clear on empty list is no-op', () async {
      await HistoryService.clearSearchHistory();
      final history = await HistoryService.getSearchHistory();
      expect(history, isEmpty);
    });
  });

  group('getRecentWallpapers', () {
    test('returns empty list when no data', () async {
      final recent = await HistoryService.getRecentWallpapers();
      expect(recent, isEmpty);
    });

    test('returns wallpapers from stored JSON', () async {
      final wp = _makeWallpaper(id: 'uuid-1', wallhavenId: 'abc');
      final jsonList = [
        {
          'id': wp.id,
          'wallhaven_id': wp.wallhavenId,
          'url_full': wp.urlFull,
          'url_thumb': wp.urlThumb,
          'resolution': wp.resolution,
          'width': wp.width,
          'height': wp.height,
          'file_size': wp.fileSize,
          'primary_color': wp.primaryColor,
          'category': wp.category,
          'source_query': wp.sourceQuery,
          'created_at': wp.createdAt.toIso8601String(),
        },
      ];
      SharedPreferences.setMockInitialValues({
        'recent_wallpapers': json.encode(jsonList),
      });

      final recent = await HistoryService.getRecentWallpapers();
      expect(recent.length, 1);
      expect(recent.first.wallhavenId, 'abc');
    });

    test('returns empty list for invalid JSON', () async {
      SharedPreferences.setMockInitialValues({
        'recent_wallpapers': 'not valid json',
      });
      final recent = await HistoryService.getRecentWallpapers();
      expect(recent, isEmpty);
    });
  });

  group('addRecentWallpaper', () {
    test('adds wallpaper to empty list', () async {
      final wp = _makeWallpaper();
      await HistoryService.addRecentWallpaper(wp);
      final recent = await HistoryService.getRecentWallpapers();
      expect(recent.length, 1);
      expect(recent.first.wallhavenId, wp.wallhavenId);
    });

    test('adds to front of existing list', () async {
      final wp1 = _makeWallpaper(id: 'uuid-1', wallhavenId: 'aaa');
      final wp2 = _makeWallpaper(id: 'uuid-2', wallhavenId: 'bbb');
      await HistoryService.addRecentWallpaper(wp1);
      await HistoryService.addRecentWallpaper(wp2);
      final recent = await HistoryService.getRecentWallpapers();
      expect(recent.length, 2);
      expect(recent.first.wallhavenId, 'bbb');
      expect(recent.last.wallhavenId, 'aaa');
    });

    test('removes duplicate by wallhavenId and moves to front', () async {
      final wp1 = _makeWallpaper(id: 'uuid-1', wallhavenId: 'aaa');
      final wp2 = _makeWallpaper(id: 'uuid-2', wallhavenId: 'bbb');
      final wp1Updated = _makeWallpaper(id: 'uuid-1-v2', wallhavenId: 'aaa');
      await HistoryService.addRecentWallpaper(wp1);
      await HistoryService.addRecentWallpaper(wp2);
      await HistoryService.addRecentWallpaper(wp1Updated);

      final recent = await HistoryService.getRecentWallpapers();
      expect(recent.length, 2);
      expect(recent.first.wallhavenId, 'aaa');
      expect(recent.first.id, 'uuid-1-v2');
      expect(recent.last.wallhavenId, 'bbb');
    });

    test('caps at 20 items', () async {
      for (var i = 1; i <= 21; i++) {
        await HistoryService.addRecentWallpaper(
          _makeWallpaper(id: 'uuid-$i', wallhavenId: 'id$i'),
        );
      }
      final recent = await HistoryService.getRecentWallpapers();
      expect(recent.length, 20);
      expect(recent.first.wallhavenId, 'id21');
      expect(recent.last.wallhavenId, 'id2');
    });

    test('persists data correctly through round-trip', () async {
      final wp = _makeWallpaper(id: 'uuid-1', wallhavenId: 'xyz');
      await HistoryService.addRecentWallpaper(wp);
      final recent = await HistoryService.getRecentWallpapers();
      final r = recent.first;
      expect(r.id, 'uuid-1');
      expect(r.wallhavenId, 'xyz');
      expect(r.urlFull, wp.urlFull);
      expect(r.urlThumb, wp.urlThumb);
      expect(r.resolution, wp.resolution);
      expect(r.width, wp.width);
      expect(r.height, wp.height);
      expect(r.fileSize, wp.fileSize);
      expect(r.primaryColor, wp.primaryColor);
      expect(r.category, wp.category);
      expect(r.sourceQuery, wp.sourceQuery);
    });
  });

  group('clearRecentWallpapers', () {
    test('clears all recent wallpapers', () async {
      await HistoryService.addRecentWallpaper(_makeWallpaper());
      await HistoryService.clearRecentWallpapers();
      final recent = await HistoryService.getRecentWallpapers();
      expect(recent, isEmpty);
    });

    test('clear on empty list is no-op', () async {
      await HistoryService.clearRecentWallpapers();
      final recent = await HistoryService.getRecentWallpapers();
      expect(recent, isEmpty);
    });
  });
}
