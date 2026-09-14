import 'package:flutter_test/flutter_test.dart';
import 'package:wallbizz/models/downloaded_wallpaper.dart';

void main() {
  group('DownloadedWallpaper constructor', () {
    test('creates instance with all required fields', () {
      final wp = DownloadedWallpaper(
        wallhavenId: 'abc123',
        localPath: '/tmp/abc123.jpg',
        urlFull: 'https://w.wallhaven.cc/full/ab/wallhaven-abc123.jpg',
        urlThumb: 'https://th.wallhaven.cc/small/ab/abc123.jpg',
        sourceQuery: 'trending',
        category: 'general',
        primaryColor: '#ff0000',
        resolution: '1920x1080',
        width: 1920,
        height: 1080,
        fileSize: 2000000,
        downloadedAt: DateTime(2024, 6, 15),
      );

      expect(wp.wallhavenId, 'abc123');
      expect(wp.localPath, '/tmp/abc123.jpg');
      expect(wp.urlFull, contains('wallhaven-abc123.jpg'));
      expect(wp.urlThumb, contains('abc123'));
      expect(wp.sourceQuery, 'trending');
      expect(wp.category, 'general');
      expect(wp.primaryColor, '#ff0000');
      expect(wp.resolution, '1920x1080');
      expect(wp.width, 1920);
      expect(wp.height, 1080);
      expect(wp.fileSize, 2000000);
      expect(wp.downloadedAt, DateTime(2024, 6, 15));
    });
  });

  group('aspectRatio', () {
    test('calculates 16:9 ratio', () {
      final wp = DownloadedWallpaper(
        wallhavenId: 'a',
        localPath: '',
        urlFull: '',
        urlThumb: '',
        sourceQuery: '',
        category: '',
        primaryColor: '#000000',
        resolution: '1920x1080',
        width: 1920,
        height: 1080,
        fileSize: 0,
        downloadedAt: DateTime.now(),
      );
      expect(wp.aspectRatio, closeTo(16 / 9, 0.01));
    });

    test('returns 1.0 for zero height', () {
      final wp = DownloadedWallpaper(
        wallhavenId: 'a',
        localPath: '',
        urlFull: '',
        urlThumb: '',
        sourceQuery: '',
        category: '',
        primaryColor: '#000000',
        resolution: '0x0',
        width: 0,
        height: 0,
        fileSize: 0,
        downloadedAt: DateTime.now(),
      );
      expect(wp.aspectRatio, 1.0);
    });
  });

  group('formattedFileSize', () {
    test('formats bytes to KB', () {
      final wp = DownloadedWallpaper(
        wallhavenId: 'a',
        localPath: '',
        urlFull: '',
        urlThumb: '',
        sourceQuery: '',
        category: '',
        primaryColor: '#000000',
        resolution: '',
        width: 0,
        height: 0,
        fileSize: 512000,
        downloadedAt: DateTime.now(),
      );
      expect(wp.formattedFileSize, '500.0 KB');
    });

    test('formats bytes to MB', () {
      final wp = DownloadedWallpaper(
        wallhavenId: 'a',
        localPath: '',
        urlFull: '',
        urlThumb: '',
        sourceQuery: '',
        category: '',
        primaryColor: '#000000',
        resolution: '',
        width: 0,
        height: 0,
        fileSize: 4200000,
        downloadedAt: DateTime.now(),
      );
      expect(wp.formattedFileSize, '4.0 MB');
    });

    test('formats exactly 1MB', () {
      final wp = DownloadedWallpaper(
        wallhavenId: 'a',
        localPath: '',
        urlFull: '',
        urlThumb: '',
        sourceQuery: '',
        category: '',
        primaryColor: '#000000',
        resolution: '',
        width: 0,
        height: 0,
        fileSize: 1048576,
        downloadedAt: DateTime.now(),
      );
      expect(wp.formattedFileSize, '1.0 MB');
    });

    test('formats zero bytes', () {
      final wp = DownloadedWallpaper(
        wallhavenId: 'a',
        localPath: '',
        urlFull: '',
        urlThumb: '',
        sourceQuery: '',
        category: '',
        primaryColor: '#000000',
        resolution: '',
        width: 0,
        height: 0,
        fileSize: 0,
        downloadedAt: DateTime.now(),
      );
      expect(wp.formattedFileSize, '0.0 KB');
    });
  });

  group('toMap', () {
    test('serializes all fields', () {
      final dt = DateTime(2024, 3, 10, 12, 0);
      final wp = DownloadedWallpaper(
        wallhavenId: 'xyz',
        localPath: '/data/xyz.jpg',
        urlFull: 'https://w.wallhaven.cc/full/xy/wallhaven-xyz.jpg',
        urlThumb: 'https://th.wallhaven.cc/small/xy/xyz.jpg',
        sourceQuery: 'nature',
        category: 'general',
        primaryColor: '#00ff00',
        resolution: '2560x1440',
        width: 2560,
        height: 1440,
        fileSize: 3500000,
        downloadedAt: dt,
      );

      final map = wp.toMap();
      expect(map['wallhavenId'], 'xyz');
      expect(map['localPath'], '/data/xyz.jpg');
      expect(map['urlFull'], contains('wallhaven-xyz'));
      expect(map['urlThumb'], contains('xyz'));
      expect(map['sourceQuery'], 'nature');
      expect(map['category'], 'general');
      expect(map['primaryColor'], '#00ff00');
      expect(map['resolution'], '2560x1440');
      expect(map['width'], 2560);
      expect(map['height'], 1440);
      expect(map['fileSize'], 3500000);
      expect(map['downloadedAt'], dt.toIso8601String());
    });
  });

  group('fromMap', () {
    test('deserializes all fields', () {
      final dt = DateTime(2024, 3, 10, 12, 0);
      final map = {
        'wallhavenId': 'xyz',
        'localPath': '/data/xyz.jpg',
        'urlFull': 'https://w.wallhaven.cc/full/xy/wallhaven-xyz.jpg',
        'urlThumb': 'https://th.wallhaven.cc/small/xy/xyz.jpg',
        'sourceQuery': 'nature',
        'category': 'general',
        'primaryColor': '#00ff00',
        'resolution': '2560x1440',
        'width': 2560,
        'height': 1440,
        'fileSize': 3500000,
        'downloadedAt': dt.toIso8601String(),
      };

      final wp = DownloadedWallpaper.fromMap(map);
      expect(wp.wallhavenId, 'xyz');
      expect(wp.localPath, '/data/xyz.jpg');
      expect(wp.urlFull, contains('wallhaven-xyz'));
      expect(wp.urlThumb, contains('xyz'));
      expect(wp.sourceQuery, 'nature');
      expect(wp.category, 'general');
      expect(wp.primaryColor, '#00ff00');
      expect(wp.resolution, '2560x1440');
      expect(wp.width, 2560);
      expect(wp.height, 1440);
      expect(wp.fileSize, 3500000);
      expect(wp.downloadedAt, dt);
    });

    test('handles missing fields with defaults', () {
      final wp = DownloadedWallpaper.fromMap(<dynamic, dynamic>{});
      expect(wp.wallhavenId, '');
      expect(wp.localPath, '');
      expect(wp.urlFull, '');
      expect(wp.urlThumb, '');
      expect(wp.sourceQuery, '');
      expect(wp.category, '');
      expect(wp.primaryColor, '#000000');
      expect(wp.resolution, '');
      expect(wp.width, 0);
      expect(wp.height, 0);
      expect(wp.fileSize, 0);
      expect(wp.downloadedAt, isA<DateTime>());
    });

    test('handles invalid date string gracefully', () {
      final map = {'wallhavenId': 'a', 'downloadedAt': 'not-a-date'};
      final wp = DownloadedWallpaper.fromMap(map);
      expect(wp.downloadedAt, isA<DateTime>());
    });

    test('round-trips through toMap and fromMap', () {
      final original = DownloadedWallpaper(
        wallhavenId: 'abc',
        localPath: '/tmp/abc.jpg',
        urlFull: 'https://example.com/full.jpg',
        urlThumb: 'https://example.com/thumb.jpg',
        sourceQuery: 'cyberpunk',
        category: 'anime',
        primaryColor: '#123456',
        resolution: '3840x2160',
        width: 3840,
        height: 2160,
        fileSize: 8000000,
        downloadedAt: DateTime(2024, 8, 20, 14, 30),
      );

      final restored = DownloadedWallpaper.fromMap(original.toMap());
      expect(restored.wallhavenId, original.wallhavenId);
      expect(restored.localPath, original.localPath);
      expect(restored.urlFull, original.urlFull);
      expect(restored.urlThumb, original.urlThumb);
      expect(restored.sourceQuery, original.sourceQuery);
      expect(restored.category, original.category);
      expect(restored.primaryColor, original.primaryColor);
      expect(restored.resolution, original.resolution);
      expect(restored.width, original.width);
      expect(restored.height, original.height);
      expect(restored.fileSize, original.fileSize);
      expect(restored.downloadedAt, original.downloadedAt);
    });
  });
}
