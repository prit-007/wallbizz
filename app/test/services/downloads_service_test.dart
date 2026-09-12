import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wallbizz/models/downloaded_wallpaper.dart';
import 'package:wallbizz/services/downloads_service.dart';

DownloadedWallpaper _makeDownload({
  String id = 'wp1',
  String sourceQuery = 'trending',
  String resolution = '1920x1080',
  String category = 'general',
}) {
  return DownloadedWallpaper(
    wallhavenId: id,
    localPath: '/tmp/$id.jpg',
    urlFull: 'https://example.com/$id.jpg',
    urlThumb: 'https://example.com/${id}_sm.jpg',
    sourceQuery: sourceQuery,
    category: category,
    primaryColor: '#ff0000',
    resolution: resolution,
    width: 1920,
    height: 1080,
    fileSize: 1000000,
    downloadedAt: DateTime(2024, 1, 15),
  );
}

void main() {
  late Box box;

  setUpAll(() async {
    if (!Hive.isBoxOpen('downloads')) {
      final dir = Directory.systemTemp.createTempSync('hive_test_');
      Hive.init(dir.path);
      await Hive.openBox('downloads');
    }
  });

  setUp(() async {
    box = Hive.box('downloads');
    await box.clear();
  });

  group('DownloadsService', () {
    test('isDownloaded returns false for unknown id', () {
      expect(DownloadsService.isDownloaded('unknown'), false);
    });

    test('getDownloads returns empty list when no downloads', () {
      final downloads = DownloadsService.getDownloads();
      expect(downloads, isEmpty);
    });

    test('downloadCount returns 0 for empty box', () {
      expect(DownloadsService.downloadCount, 0);
    });

    test('isDownloaded returns true after adding entry', () async {
      final wp = _makeDownload(id: 'test123');
      await box.put('test123', wp.toMap());
      expect(DownloadsService.isDownloaded('test123'), true);
      expect(DownloadsService.isDownloaded('other'), false);
    });

    test('downloadCount reflects box length', () async {
      expect(DownloadsService.downloadCount, 0);
      await box.put('wp1', _makeDownload(id: 'wp1').toMap());
      expect(DownloadsService.downloadCount, 1);
      await box.put('wp2', _makeDownload(id: 'wp2').toMap());
      expect(DownloadsService.downloadCount, 2);
    });

    test('getDownloads returns all items when no search query', () async {
      await box.put('wp1', _makeDownload(id: 'wp1').toMap());
      await box.put('wp2', _makeDownload(id: 'wp2').toMap());
      final results = DownloadsService.getDownloads();
      expect(results.length, 2);
    });

    test('getDownloads filters by sourceQuery', () async {
      await box.put(
        'wp1',
        _makeDownload(id: 'wp1', sourceQuery: 'cyberpunk').toMap(),
      );
      await box.put(
        'wp2',
        _makeDownload(id: 'wp2', sourceQuery: 'nature').toMap(),
      );

      final cyberpunkResults = DownloadsService.getDownloads(
        searchQuery: 'cyberpunk',
      );
      expect(cyberpunkResults.length, 1);
      expect(cyberpunkResults.first.sourceQuery, 'cyberpunk');
    });

    test('getDownloads filters by category', () async {
      await box.put('wp1', _makeDownload(id: 'wp1', category: 'anime').toMap());
      await box.put(
        'wp2',
        _makeDownload(id: 'wp2', category: 'general').toMap(),
      );

      final animeResults = DownloadsService.getDownloads(searchQuery: 'anime');
      expect(animeResults.length, 1);
      expect(animeResults.first.category, 'anime');
    });

    test('getDownloads filters by resolution', () async {
      await box.put(
        'wp1',
        _makeDownload(id: 'wp1', resolution: '1920x1080').toMap(),
      );
      await box.put(
        'wp2',
        _makeDownload(id: 'wp2', resolution: '3840x2160').toMap(),
      );

      final hdResults = DownloadsService.getDownloads(searchQuery: '3840');
      expect(hdResults.length, 1);
      expect(hdResults.first.resolution, '3840x2160');
    });

    test('getDownloads filters by primaryColor', () async {
      final wp1 = DownloadedWallpaper(
        wallhavenId: 'wp1',
        localPath: '/tmp/wp1.jpg',
        urlFull: '',
        urlThumb: '',
        sourceQuery: '',
        category: '',
        primaryColor: '#ff0000',
        resolution: '',
        width: 0,
        height: 0,
        fileSize: 0,
        downloadedAt: DateTime(2024, 1, 1),
      );
      final wp2 = DownloadedWallpaper(
        wallhavenId: 'wp2',
        localPath: '/tmp/wp2.jpg',
        urlFull: '',
        urlThumb: '',
        sourceQuery: '',
        category: '',
        primaryColor: '#00ff00',
        resolution: '',
        width: 0,
        height: 0,
        fileSize: 0,
        downloadedAt: DateTime(2024, 1, 1),
      );
      await box.put('wp1', wp1.toMap());
      await box.put('wp2', wp2.toMap());

      final redResults = DownloadsService.getDownloads(searchQuery: '#ff0000');
      expect(redResults.length, 1);
      expect(redResults.first.primaryColor, '#ff0000');
    });

    test('getDownloads returns empty for non-matching query', () async {
      await box.put(
        'wp1',
        _makeDownload(id: 'wp1', sourceQuery: 'cyberpunk').toMap(),
      );
      final results = DownloadsService.getDownloads(searchQuery: 'nature');
      expect(results, isEmpty);
    });
  });
}
