import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/models/wallpaper.dart';

void main() {
  Wallpaper makeWp({
    String id = '1',
    int width = 1920,
    int height = 1080,
    int fileSize = 2000000,
    String primaryColor = '#000000',
    String category = 'general',
    String sourceQuery = 'trending',
  }) {
    return Wallpaper(
      id: id,
      wallhavenId: 'abc',
      urlFull: 'https://example.com/full.jpg',
      urlThumb: 'https://example.com/thumb.jpg',
      resolution: '${width}x$height',
      width: width,
      height: height,
      fileSize: fileSize,
      primaryColor: primaryColor,
      category: category,
      sourceQuery: sourceQuery,
      createdAt: DateTime(2024, 6, 15),
    );
  }

  group('Wallpaper.fromMap — edge cases', () {
    test('all fields provided', () {
      final map = {
        'id': 'uuid-1',
        'wallhaven_id': 'abc',
        'url_full': 'https://full.jpg',
        'url_thumb': 'https://thumb.jpg',
        'resolution': '1920x1080',
        'width': 1920,
        'height': 1080,
        'file_size': 2000000,
        'primary_color': '#FF0000',
        'category': 'anime',
        'source_query': 'anime',
        'created_at': '2024-01-15T10:30:00Z',
      };

      final wp = Wallpaper.fromMap(map);
      expect(wp.id, 'uuid-1');
      expect(wp.wallhavenId, 'abc');
      expect(wp.urlFull, 'https://full.jpg');
      expect(wp.urlThumb, 'https://thumb.jpg');
      expect(wp.resolution, '1920x1080');
      expect(wp.width, 1920);
      expect(wp.height, 1080);
      expect(wp.fileSize, 2000000);
      expect(wp.primaryColor, '#FF0000');
      expect(wp.category, 'anime');
      expect(wp.sourceQuery, 'anime');
    });

    test('completely empty map', () {
      final wp = Wallpaper.fromMap({});
      expect(wp.id, '');
      expect(wp.wallhavenId, '');
      expect(wp.urlFull, '');
      expect(wp.urlThumb, '');
      expect(wp.resolution, '');
      expect(wp.width, 0);
      expect(wp.height, 0);
      expect(wp.fileSize, 0);
      expect(wp.primaryColor, '#000000');
      expect(wp.category, 'general');
      expect(wp.sourceQuery, '');
    });

    test('null values in map', () {
      final map = <String, dynamic>{
        'id': null,
        'wallhaven_id': null,
        'url_full': null,
        'url_thumb': null,
        'resolution': null,
        'width': null,
        'height': null,
        'file_size': null,
        'primary_color': null,
        'category': null,
        'source_query': null,
        'created_at': null,
      };

      final wp = Wallpaper.fromMap(map);
      expect(wp.id, '');
      expect(wp.primaryColor, '#000000');
      expect(wp.category, 'general');
    });

    test('negative dimensions', () {
      final map = {
        'id': 'neg',
        'width': -100,
        'height': -200,
        'created_at': '2024-01-01T00:00:00Z',
      };

      final wp = Wallpaper.fromMap(map);
      expect(wp.width, -100);
      expect(wp.height, -200);
      expect(wp.aspectRatio, closeTo(0.5, 0.01));
    });

    test('very large dimensions (8K)', () {
      final map = {
        'id': '8k',
        'width': 7680,
        'height': 4320,
        'file_size': 15000000,
        'created_at': '2024-01-01T00:00:00Z',
      };

      final wp = Wallpaper.fromMap(map);
      expect(wp.width, 7680);
      expect(wp.height, 4320);
      expect(wp.aspectRatio, closeTo(7680 / 4320, 0.01));
      expect(wp.formattedFileSize, '14.3 MB');
    });
  });

  group('Wallpaper.aspectRatio — edge cases', () {
    test('square (1:1)', () {
      final wp = makeWp(width: 1080, height: 1080);
      expect(wp.aspectRatio, closeTo(1.0, 0.01));
    });

    test('extreme wide (32:9)', () {
      final wp = makeWp(width: 5120, height: 1440);
      expect(wp.aspectRatio, closeTo(32 / 9, 0.01));
    });

    test('extreme tall (1:3)', () {
      final wp = makeWp(width: 500, height: 1500);
      expect(wp.aspectRatio, closeTo(1 / 3, 0.01));
    });

    test('height=1', () {
      final wp = makeWp(width: 1920, height: 1);
      expect(wp.aspectRatio, closeTo(1920.0, 0.01));
    });

    test('width=1', () {
      final wp = makeWp(width: 1, height: 1080);
      expect(wp.aspectRatio, closeTo(1 / 1080, 0.01));
    });
  });

  group('Wallpaper.formattedFileSize — edge cases', () {
    test('1 byte', () {
      final wp = makeWp(fileSize: 1);
      expect(wp.formattedFileSize, '0.0 KB');
    });

    test('1024 bytes = 1 KB', () {
      final wp = makeWp(fileSize: 1024);
      expect(wp.formattedFileSize, '1.0 KB');
    });

    test('1048576 bytes = 1 MB', () {
      final wp = makeWp(fileSize: 1048576);
      expect(wp.formattedFileSize, '1.0 MB');
    });

    test('10 GB', () {
      final wp = makeWp(fileSize: 10 * 1024 * 1024 * 1024);
      expect(wp.formattedFileSize, '10240.0 MB');
    });

    test('boundary: 1048575 bytes (just under 1MB)', () {
      final wp = makeWp(fileSize: 1048575);
      expect(wp.formattedFileSize, '1024.0 KB');
    });

    test('boundary: 1048576 bytes (exactly 1MB)', () {
      final wp = makeWp(fileSize: 1048576);
      expect(wp.formattedFileSize, '1.0 MB');
    });

    test('boundary: 1023999 bytes (just under 1000 KB)', () {
      final wp = makeWp(fileSize: 1023999);
      expect(wp.formattedFileSize, '1000.0 KB');
    });
  });

  group('Wallpaper — constructor', () {
    test('creates instance with all required fields', () {
      final wp = Wallpaper(
        id: 'test',
        wallhavenId: 'abc',
        urlFull: 'https://full.jpg',
        urlThumb: 'https://thumb.jpg',
        resolution: '1920x1080',
        width: 1920,
        height: 1080,
        fileSize: 2000000,
        primaryColor: '#FF0000',
        category: 'anime',
        sourceQuery: 'anime',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(wp.id, 'test');
      expect(wp.wallhavenId, 'abc');
      expect(wp.urlFull, 'https://full.jpg');
      expect(wp.urlThumb, 'https://thumb.jpg');
      expect(wp.resolution, '1920x1080');
      expect(wp.width, 1920);
      expect(wp.height, 1080);
      expect(wp.fileSize, 2000000);
      expect(wp.primaryColor, '#FF0000');
      expect(wp.category, 'anime');
      expect(wp.sourceQuery, 'anime');
      expect(wp.createdAt, DateTime(2024, 1, 1));
    });

    test('fields are immutable', () {
      final wp = makeWp(id: 'immutable');
      // Dart final fields are immutable by convention
      expect(wp.id, 'immutable');
    });
  });

  group('Wallpaper.fromMap — date parsing', () {
    test('valid ISO date', () {
      final map = {'id': '1', 'created_at': '2024-06-15T14:30:00Z'};
      final wp = Wallpaper.fromMap(map);
      expect(wp.createdAt.year, 2024);
      expect(wp.createdAt.month, 6);
      expect(wp.createdAt.day, 15);
    });

    test('valid date with timezone offset', () {
      final map = {'id': '1', 'created_at': '2024-06-15T14:30:00+05:30'};
      final wp = Wallpaper.fromMap(map);
      expect(wp.createdAt.year, 2024);
    });

    test('empty date string defaults to DateTime.now()', () {
      final before = DateTime.now();
      final map = {'id': '1', 'created_at': ''};
      final wp = Wallpaper.fromMap(map);
      final after = DateTime.now();
      expect(
        wp.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        wp.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('null date defaults to DateTime.now()', () {
      final before = DateTime.now();
      final map = <String, dynamic>{'id': '1'};
      final wp = Wallpaper.fromMap(map);
      final after = DateTime.now();
      expect(
        wp.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        wp.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });
  });
}
