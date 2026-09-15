import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wallbizz/services/hive_moodboard_service.dart';
import 'package:wallbizz/models/wallpaper.dart';

Wallpaper _makeWp({
  String id = 'abc',
  String urlFull = 'https://example.com/abc.jpg',
  String urlThumb = 'https://example.com/abc_sm.jpg',
}) {
  return Wallpaper(
    id: 'wh-$id',
    wallhavenId: id,
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
    if (!Hive.isBoxOpen('moodboards')) {
      final dir = Directory.systemTemp.createTempSync('hive_moodboard_test_');
      Hive.init(dir.path);
      await Hive.openBox('moodboards');
    }
  });

  setUp(() async {
    box = Hive.box('moodboards');
    await box.clear();
    HiveMoodboardService.moodboardNotifier.value = 0;
  });

  group('HiveMoodboardService.getMoodboards', () {
    test('returns empty for unknown user', () async {
      final boards = await HiveMoodboardService.getMoodboards('user1');
      expect(boards, isEmpty);
    });

    test('returns stored moodboards', () async {
      await HiveMoodboardService.createMoodboard('user1', 'Nature');
      final boards = await HiveMoodboardService.getMoodboards('user1');
      expect(boards.length, 1);
      expect(boards.first.name, 'Nature');
    });
  });

  group('HiveMoodboardService.createMoodboard', () {
    test('creates moodboard', () async {
      final board = await HiveMoodboardService.createMoodboard(
        'user1',
        'Board',
      );
      expect(board, isNotNull);
      expect(board!.name, 'Board');
    });

    test('returns null for empty name', () async {
      final board = await HiveMoodboardService.createMoodboard('user1', '');
      expect(board, isNull);
    });

    test('increments notifier', () async {
      expect(HiveMoodboardService.moodboardNotifier.value, 0);
      await HiveMoodboardService.createMoodboard('user1', 'Board');
      expect(HiveMoodboardService.moodboardNotifier.value, 1);
    });
  });

  group('HiveMoodboardService.deleteMoodboard', () {
    test('deletes moodboard', () async {
      final board = await HiveMoodboardService.createMoodboard(
        'user1',
        'Board',
      );
      final deleted = await HiveMoodboardService.deleteMoodboard(
        'user1',
        board!.id,
      );
      expect(deleted, true);
      expect((await HiveMoodboardService.getMoodboards('user1')).length, 0);
    });

    test('returns false for non-existent', () async {
      final deleted = await HiveMoodboardService.deleteMoodboard(
        'user1',
        'nope',
      );
      expect(deleted, false);
    });
  });

  group('HiveMoodboardService.getWallpapers', () {
    test('returns empty for unknown moodboard', () async {
      final wps = await HiveMoodboardService.getWallpapers('nonexistent');
      expect(wps, isEmpty);
    });

    test('returns wallpapers in moodboard', () async {
      final board = await HiveMoodboardService.createMoodboard(
        'user1',
        'Board',
      );
      await HiveMoodboardService.addWallpaper(board!.id, _makeWp(id: 'abc'));
      await HiveMoodboardService.addWallpaper(board.id, _makeWp(id: 'def'));
      final wps = await HiveMoodboardService.getWallpapers(board.id);
      expect(wps.length, 2);
    });

    test('preserves wallpaper data', () async {
      final board = await HiveMoodboardService.createMoodboard(
        'user1',
        'Board',
      );
      final wp = _makeWp(id: 'abc', urlFull: 'https://img/abc.jpg');
      await HiveMoodboardService.addWallpaper(board!.id, wp);
      final wps = await HiveMoodboardService.getWallpapers(board.id);
      expect(wps.first.urlFull, 'https://img/abc.jpg');
    });
  });

  group('HiveMoodboardService.containsWallpaper', () {
    test('returns false for unknown moodboard', () async {
      expect(
        await HiveMoodboardService.containsWallpaper('nope', 'abc'),
        false,
      );
    });

    test('returns true when contains', () async {
      final board = await HiveMoodboardService.createMoodboard(
        'user1',
        'Board',
      );
      await HiveMoodboardService.addWallpaper(board!.id, _makeWp(id: 'abc'));
      expect(
        await HiveMoodboardService.containsWallpaper(board.id, 'abc'),
        true,
      );
    });

    test('returns false when not contains', () async {
      final board = await HiveMoodboardService.createMoodboard(
        'user1',
        'Board',
      );
      expect(
        await HiveMoodboardService.containsWallpaper(board!.id, 'xyz'),
        false,
      );
    });
  });

  group('HiveMoodboardService.addWallpaper', () {
    test('adds wallpaper', () async {
      final board = await HiveMoodboardService.createMoodboard(
        'user1',
        'Board',
      );
      final added = await HiveMoodboardService.addWallpaper(
        board!.id,
        _makeWp(id: 'abc'),
      );
      expect(added, true);
      final wps = await HiveMoodboardService.getWallpapers(board.id);
      expect(wps.length, 1);
    });

    test('does not add duplicate', () async {
      final board = await HiveMoodboardService.createMoodboard(
        'user1',
        'Board',
      );
      await HiveMoodboardService.addWallpaper(board!.id, _makeWp(id: 'abc'));
      await HiveMoodboardService.addWallpaper(board.id, _makeWp(id: 'abc'));
      final wps = await HiveMoodboardService.getWallpapers(board.id);
      expect(wps.length, 1);
    });

    test('adds to multiple moodboards', () async {
      final b1 = await HiveMoodboardService.createMoodboard('user1', 'Board 1');
      final b2 = await HiveMoodboardService.createMoodboard('user1', 'Board 2');
      await HiveMoodboardService.addWallpaper(b1!.id, _makeWp(id: 'abc'));
      await HiveMoodboardService.addWallpaper(b2!.id, _makeWp(id: 'abc'));
      expect(await HiveMoodboardService.containsWallpaper(b1.id, 'abc'), true);
      expect(await HiveMoodboardService.containsWallpaper(b2.id, 'abc'), true);
    });

    test('increments notifier', () async {
      final board = await HiveMoodboardService.createMoodboard(
        'user1',
        'Board',
      );
      expect(HiveMoodboardService.moodboardNotifier.value, 1);
      await HiveMoodboardService.addWallpaper(board!.id, _makeWp(id: 'abc'));
      expect(HiveMoodboardService.moodboardNotifier.value, 2);
    });

    test('returns false for non-existent moodboard', () async {
      final added = await HiveMoodboardService.addWallpaper(
        'nope',
        _makeWp(id: 'abc'),
      );
      expect(added, false);
    });
  });

  group('HiveMoodboardService.removeWallpaper', () {
    test('removes wallpaper', () async {
      final board = await HiveMoodboardService.createMoodboard(
        'user1',
        'Board',
      );
      await HiveMoodboardService.addWallpaper(board!.id, _makeWp(id: 'abc'));
      await HiveMoodboardService.addWallpaper(board.id, _makeWp(id: 'def'));
      await HiveMoodboardService.removeWallpaper(board.id, 'abc');
      final wps = await HiveMoodboardService.getWallpapers(board.id);
      expect(wps.length, 1);
      expect(wps.first.wallhavenId, 'def');
    });

    test('removing non-existent is no-op', () async {
      final board = await HiveMoodboardService.createMoodboard(
        'user1',
        'Board',
      );
      await HiveMoodboardService.addWallpaper(board!.id, _makeWp(id: 'abc'));
      await HiveMoodboardService.removeWallpaper(board.id, 'xyz');
      final wps = await HiveMoodboardService.getWallpapers(board.id);
      expect(wps.length, 1);
    });

    test('increments notifier', () async {
      final board = await HiveMoodboardService.createMoodboard(
        'user1',
        'Board',
      );
      await HiveMoodboardService.addWallpaper(board!.id, _makeWp(id: 'abc'));
      HiveMoodboardService.moodboardNotifier.value = 10;
      await HiveMoodboardService.removeWallpaper(board.id, 'abc');
      expect(HiveMoodboardService.moodboardNotifier.value, 11);
    });

    test('returns false for non-existent moodboard', () async {
      final removed = await HiveMoodboardService.removeWallpaper('nope', 'abc');
      expect(removed, false);
    });
  });

  group('HiveMoodboardService.getMoodboardsForWallpaper', () {
    test('returns empty for unknown wallpaper', () async {
      final boards = await HiveMoodboardService.getMoodboardsForWallpaper(
        'user1',
        'xyz',
      );
      expect(boards, isEmpty);
    });

    test('returns moodboards containing wallpaper', () async {
      final b1 = await HiveMoodboardService.createMoodboard('user1', 'Board 1');
      final b2 = await HiveMoodboardService.createMoodboard('user1', 'Board 2');
      await HiveMoodboardService.addWallpaper(b1!.id, _makeWp(id: 'abc'));
      await HiveMoodboardService.addWallpaper(b2!.id, _makeWp(id: 'abc'));
      final boards = await HiveMoodboardService.getMoodboardsForWallpaper(
        'user1',
        'abc',
      );
      expect(boards.length, 2);
    });

    test('returns only matching', () async {
      final b1 = await HiveMoodboardService.createMoodboard('user1', 'Board 1');
      final b2 = await HiveMoodboardService.createMoodboard('user1', 'Board 2');
      await HiveMoodboardService.addWallpaper(b1!.id, _makeWp(id: 'abc'));
      await HiveMoodboardService.addWallpaper(b2!.id, _makeWp(id: 'xyz'));
      final boards = await HiveMoodboardService.getMoodboardsForWallpaper(
        'user1',
        'abc',
      );
      expect(boards.length, 1);
      expect(boards.first.id, b1.id);
    });
  });

  group('HiveMoodboardService.setAll', () {
    test('replaces all moodboards', () async {
      await HiveMoodboardService.createMoodboard('user1', 'Old');
      await HiveMoodboardService.setAll('user1', [
        {
          'id': 'new1',
          'name': 'New',
          'wallpapers': [],
          'created_at': '2024-01-01T00:00:00.000',
        },
      ]);
      final boards = await HiveMoodboardService.getMoodboards('user1');
      expect(boards.length, 1);
      expect(boards.first.name, 'New');
    });

    test('does not increment notifier (silent sync)', () async {
      HiveMoodboardService.moodboardNotifier.value = 0;
      await HiveMoodboardService.setAll('user1', [
        {
          'id': 'b1',
          'name': 'B',
          'wallpapers': [],
          'created_at': '2024-01-01T00:00:00.000',
        },
      ]);
      expect(HiveMoodboardService.moodboardNotifier.value, 0);
    });
  });
}
