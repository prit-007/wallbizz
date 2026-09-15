import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:wallbizz/services/sync_service.dart';
import 'package:wallbizz/services/hive_wishlist_service.dart';
import 'package:wallbizz/services/hive_moodboard_service.dart';
import 'package:wallbizz/models/wallpaper.dart';

Wallpaper _makeWp(String id) {
  return Wallpaper(
    id: 'wh-$id',
    wallhavenId: id,
    urlFull: 'https://example.com/$id.jpg',
    urlThumb: 'https://example.com/${id}_sm.jpg',
    resolution: '1920x1080',
    width: 1920,
    height: 1080,
    fileSize: 1000000,
    primaryColor: '#ff0000',
    category: 'general',
    sourceQuery: 'trending',
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  late Box wishlistsBox;
  late Box moodboardsBox;

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('sync_test_');
    Hive.init(dir.path);
    if (!Hive.isBoxOpen('wishlists')) {
      wishlistsBox = await Hive.openBox('wishlists');
    } else {
      wishlistsBox = Hive.box('wishlists');
    }
    if (!Hive.isBoxOpen('moodboards')) {
      moodboardsBox = await Hive.openBox('moodboards');
    } else {
      moodboardsBox = Hive.box('moodboards');
    }
  });

  setUp(() async {
    await wishlistsBox.clear();
    await moodboardsBox.clear();
    HiveWishlistService.wishlistNotifier.value = 0;
    HiveMoodboardService.moodboardNotifier.value = 0;
    SyncService.authenticatedUserId = null;
  });

  group('SyncService.mergeWallhavenIds', () {
    test('returns remote when local is empty', () {
      final result = SyncService.mergeWallhavenIds([], ['a', 'b', 'c']);
      expect(result, ['a', 'b', 'c']);
    });

    test('returns local when remote is empty', () {
      final result = SyncService.mergeWallhavenIds(['a', 'b'], []);
      expect(result, ['a', 'b']);
    });

    test('merges without duplicates', () {
      final result = SyncService.mergeWallhavenIds(['a', 'b'], ['b', 'c']);
      expect(result, containsAll(['a', 'b', 'c']));
      expect(result.length, 3);
    });

    test('preserves order', () {
      final result = SyncService.mergeWallhavenIds(['a', 'b'], ['c', 'd']);
      expect(result, ['a', 'b', 'c', 'd']);
    });

    test('handles both empty', () {
      final result = SyncService.mergeWallhavenIds([], []);
      expect(result, isEmpty);
    });
  });

  group('SyncService.mergeMoodboards', () {
    test('returns remote when local is empty', () {
      final remote = [
        {
          'id': 'b1',
          'name': 'Board 1',
          'wallpapers': [],
          'created_at': '2024-01-01T00:00:00.000',
        },
      ];
      final result = SyncService.mergeMoodboards([], remote);
      expect(result.length, 1);
    });

    test('returns local when remote is empty', () {
      final local = [
        {
          'id': 'b1',
          'name': 'Board 1',
          'wallpapers': [],
          'created_at': '2024-01-01T00:00:00.000',
        },
      ];
      final result = SyncService.mergeMoodboards(local, []);
      expect(result.length, 1);
    });

    test('merges by id, local wins on name conflict', () {
      final local = [
        {
          'id': 'b1',
          'name': 'Local',
          'wallpapers': [],
          'created_at': '2024-01-01T00:00:00.000',
        },
      ];
      final remote = [
        {
          'id': 'b1',
          'name': 'Remote',
          'wallpapers': [],
          'created_at': '2024-01-02T00:00:00.000',
        },
      ];
      final result = SyncService.mergeMoodboards(local, remote);
      expect(result.first['name'], 'Local');
    });

    test('merges wallpapers for shared boards', () {
      final local = [
        {
          'id': 'b1',
          'name': 'Board',
          'wallpapers': [
            {'wallhaven_id': 'a'},
          ],
          'created_at': '2024-01-01T00:00:00.000',
        },
      ];
      final remote = [
        {
          'id': 'b1',
          'name': 'Board',
          'wallpapers': [
            {'wallhaven_id': 'b'},
          ],
          'created_at': '2024-01-01T00:00:00.000',
        },
      ];
      final result = SyncService.mergeMoodboards(local, remote);
      final wps = result.first['wallpapers'] as List;
      expect(wps.length, 2);
    });

    test('handles both empty', () {
      final result = SyncService.mergeMoodboards([], []);
      expect(result, isEmpty);
    });
  });

  group('SyncService.pullToHive', () {
    test('sets wishlist data in Hive', () async {
      await SyncService.pullWishlistToHive('user1', [
        _makeWp('a'),
        _makeWp('b'),
      ]);
      final ids = await HiveWishlistService.getWallhavenIds('user1');
      expect(ids, containsAll(['a', 'b']));
    });

    test('merges with existing local data', () async {
      await HiveWishlistService.add('user1', _makeWp('local_only'));
      await SyncService.pullWishlistToHive('user1', [_makeWp('remote_only')]);
      final ids = await HiveWishlistService.getWallhavenIds('user1');
      expect(ids, containsAll(['local_only', 'remote_only']));
    });

    test('sets moodboard data in Hive', () async {
      final boards = [
        {
          'id': 'b1',
          'name': 'Board',
          'wallpapers': [],
          'created_at': '2024-01-01T00:00:00.000',
        },
      ];
      await SyncService.pullMoodboardsToHive('user1', boards);
      final result = await HiveMoodboardService.getMoodboards('user1');
      expect(result.length, 1);
    });

    test('does not increment notifiers during pull', () async {
      HiveWishlistService.wishlistNotifier.value = 0;
      HiveMoodboardService.moodboardNotifier.value = 0;
      await SyncService.pullWishlistToHive('user1', [_makeWp('a')]);
      await SyncService.pullMoodboardsToHive('user1', []);
      expect(HiveWishlistService.wishlistNotifier.value, 0);
      expect(HiveMoodboardService.moodboardNotifier.value, 0);
    });
  });

  group('SyncService.auto sync', () {
    test('onAuthStateChanged sets userId', () async {
      await SyncService.onAuthStateChanged('user1');
      expect(SyncService.authenticatedUserId, 'user1');
    });

    test('onAuthStateChanged with null clears userId', () async {
      SyncService.authenticatedUserId = 'user1';
      await SyncService.onAuthStateChanged(null);
      expect(SyncService.authenticatedUserId, isNull);
    });

    test('syncAll returns SyncResult', () async {
      final result = await SyncService.syncAll('user1');
      expect(result.success, true);
      expect(result.wishlistItems, 0);
      expect(result.moodboards, 0);
    });

    test('syncAll counts local items', () async {
      await HiveWishlistService.add('user1', _makeWp('a'));
      await HiveMoodboardService.createMoodboard('user1', 'Board');
      final result = await SyncService.syncAll('user1');
      expect(result.wishlistItems, 1);
      expect(result.moodboards, 1);
    });
  });

  group('SyncService.preferences', () {
    test('autoSyncEnabled defaults to true', () async {
      expect(SyncService.autoSyncEnabled, true);
    });
  });
}
