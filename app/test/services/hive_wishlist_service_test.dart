import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wallbizz/services/hive_wishlist_service.dart';
import 'package:wallbizz/models/wallpaper.dart';

Wallpaper _makeWp({
  String id = 'wh-abc',
  String urlFull = 'https://example.com/abc.jpg',
  String urlThumb = 'https://example.com/abc_sm.jpg',
}) {
  return Wallpaper(
    id: id,
    wallhavenId: id.replaceFirst('wh-', ''),
    urlFull: urlFull,
    urlThumb: urlThumb,
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
  late Box box;

  setUpAll(() async {
    if (!Hive.isBoxOpen('wishlists')) {
      final dir = Directory.systemTemp.createTempSync('hive_wishlist_test_');
      Hive.init(dir.path);
      await Hive.openBox('wishlists');
    }
  });

  setUp(() async {
    box = Hive.box('wishlists');
    await box.clear();
    HiveWishlistService.wishlistNotifier.value = 0;
  });

  group('HiveWishlistService.getWallpapers', () {
    test('returns empty list for unknown user', () async {
      final wps = await HiveWishlistService.getWallpapers('user1');
      expect(wps, isEmpty);
    });

    test('returns stored wallpapers', () async {
      final wp = _makeWp(id: 'abc');
      await HiveWishlistService.add('user1', wp);
      final wps = await HiveWishlistService.getWallpapers('user1');
      expect(wps.length, 1);
      expect(wps.first.wallhavenId, 'abc');
    });

    test('different users have separate lists', () async {
      await HiveWishlistService.add('user1', _makeWp(id: 'abc'));
      await HiveWishlistService.add('user2', _makeWp(id: 'xyz'));
      expect((await HiveWishlistService.getWallpapers('user1')).length, 1);
      expect((await HiveWishlistService.getWallpapers('user2')).length, 1);
    });
  });

  group('HiveWishlistService.isWishlisted', () {
    test('returns false for unknown user', () async {
      expect(await HiveWishlistService.isWishlisted('user1', 'abc'), false);
    });

    test('returns true when exists', () async {
      await HiveWishlistService.add('user1', _makeWp(id: 'abc'));
      expect(await HiveWishlistService.isWishlisted('user1', 'abc'), true);
    });

    test('returns false when not exists', () async {
      await HiveWishlistService.add('user1', _makeWp(id: 'abc'));
      expect(await HiveWishlistService.isWishlisted('user1', 'xyz'), false);
    });
  });

  group('HiveWishlistService.add', () {
    test('adds wallpaper', () async {
      await HiveWishlistService.add('user1', _makeWp(id: 'abc'));
      final wps = await HiveWishlistService.getWallpapers('user1');
      expect(wps.length, 1);
    });

    test('does not add duplicate', () async {
      await HiveWishlistService.add('user1', _makeWp(id: 'abc'));
      await HiveWishlistService.add('user1', _makeWp(id: 'abc'));
      final wps = await HiveWishlistService.getWallpapers('user1');
      expect(wps.length, 1);
    });

    test('increments notifier', () async {
      expect(HiveWishlistService.wishlistNotifier.value, 0);
      await HiveWishlistService.add('user1', _makeWp(id: 'abc'));
      expect(HiveWishlistService.wishlistNotifier.value, 1);
    });

    test('does not increment notifier for duplicate', () async {
      await HiveWishlistService.add('user1', _makeWp(id: 'abc'));
      HiveWishlistService.wishlistNotifier.value = 5;
      await HiveWishlistService.add('user1', _makeWp(id: 'abc'));
      expect(HiveWishlistService.wishlistNotifier.value, 5);
    });

    test('preserves wallpaper data', () async {
      final wp = _makeWp(id: 'abc', urlFull: 'https://img/abc.jpg');
      await HiveWishlistService.add('user1', wp);
      final wps = await HiveWishlistService.getWallpapers('user1');
      expect(wps.first.urlFull, 'https://img/abc.jpg');
      expect(wps.first.resolution, '1920x1080');
    });
  });

  group('HiveWishlistService.remove', () {
    test('removes wallpaper', () async {
      await HiveWishlistService.add('user1', _makeWp(id: 'abc'));
      await HiveWishlistService.add('user1', _makeWp(id: 'def'));
      await HiveWishlistService.remove('user1', 'abc');
      final wps = await HiveWishlistService.getWallpapers('user1');
      expect(wps.length, 1);
      expect(wps.first.wallhavenId, 'def');
    });

    test('removing non-existent is no-op', () async {
      await HiveWishlistService.add('user1', _makeWp(id: 'abc'));
      await HiveWishlistService.remove('user1', 'xyz');
      final wps = await HiveWishlistService.getWallpapers('user1');
      expect(wps.length, 1);
    });

    test('increments notifier', () async {
      await HiveWishlistService.add('user1', _makeWp(id: 'abc'));
      expect(HiveWishlistService.wishlistNotifier.value, 1);
      await HiveWishlistService.remove('user1', 'abc');
      expect(HiveWishlistService.wishlistNotifier.value, 2);
    });
  });

  group('HiveWishlistService.toggle', () {
    test('adds when not wishlisted', () async {
      final added = await HiveWishlistService.toggle(
        'user1',
        _makeWp(id: 'abc'),
      );
      expect(added, true);
      expect(await HiveWishlistService.isWishlisted('user1', 'abc'), true);
    });

    test('removes when wishlisted', () async {
      await HiveWishlistService.add('user1', _makeWp(id: 'abc'));
      final added = await HiveWishlistService.toggle(
        'user1',
        _makeWp(id: 'abc'),
      );
      expect(added, false);
      expect(await HiveWishlistService.isWishlisted('user1', 'abc'), false);
    });

    test('increments notifier on toggle', () async {
      await HiveWishlistService.toggle('user1', _makeWp(id: 'abc'));
      expect(HiveWishlistService.wishlistNotifier.value, 1);
      await HiveWishlistService.toggle('user1', _makeWp(id: 'abc'));
      expect(HiveWishlistService.wishlistNotifier.value, 2);
    });
  });

  group('HiveWishlistService.setAll', () {
    test('replaces all wallpapers', () async {
      await HiveWishlistService.add('user1', _makeWp(id: 'old'));
      await HiveWishlistService.setAll('user1', [
        _makeWp(id: 'new1'),
        _makeWp(id: 'new2'),
      ]);
      final wps = await HiveWishlistService.getWallpapers('user1');
      expect(wps.length, 2);
    });

    test('does not increment notifier (silent sync)', () async {
      HiveWishlistService.wishlistNotifier.value = 0;
      await HiveWishlistService.setAll('user1', [_makeWp(id: 'a')]);
      expect(HiveWishlistService.wishlistNotifier.value, 0);
    });
  });

  group('HiveWishlistService.getWallhavenIds', () {
    test('returns wallhaven ids', () async {
      await HiveWishlistService.add('user1', _makeWp(id: 'abc'));
      await HiveWishlistService.add('user1', _makeWp(id: 'def'));
      final ids = await HiveWishlistService.getWallhavenIds('user1');
      expect(ids, containsAll(['abc', 'def']));
    });

    test('returns empty for unknown user', () async {
      final ids = await HiveWishlistService.getWallhavenIds('unknown');
      expect(ids, isEmpty);
    });
  });
}
