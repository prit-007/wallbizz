import 'package:flutter_test/flutter_test.dart';
import 'package:wallbizz/models/wallpaper.dart';

void main() {
  group('Wallpaper.fromMap', () {
    test('parses all fields from Supabase row', () {
      final map = {
        'id': 'uuid-123',
        'wallhaven_id': '94x38z',
        'url_full': 'https://w.wallhaven.cc/full/94/wallhaven-94x38z.jpg',
        'url_thumb': 'https://th.wallhaven.cc/orig/94/94x38z.jpg',
        'resolution': '3840x2160',
        'width': 3840,
        'height': 2160,
        'file_size': 4200000,
        'primary_color': '#1a1a1a',
        'category': 'anime',
        'source_query': 'anime',
        'created_at': '2024-01-15T10:30:00Z',
      };

      final wallpaper = Wallpaper.fromMap(map);

      expect(wallpaper.id, 'uuid-123');
      expect(wallpaper.wallhavenId, '94x38z');
      expect(
        wallpaper.urlFull,
        'https://w.wallhaven.cc/full/94/wallhaven-94x38z.jpg',
      );
      expect(wallpaper.urlThumb, 'https://th.wallhaven.cc/orig/94/94x38z.jpg');
      expect(wallpaper.resolution, '3840x2160');
      expect(wallpaper.width, 3840);
      expect(wallpaper.height, 2160);
      expect(wallpaper.fileSize, 4200000);
      expect(wallpaper.primaryColor, '#1a1a1a');
      expect(wallpaper.category, 'anime');
      expect(wallpaper.sourceQuery, 'anime');
    });

    test('handles missing fields gracefully', () {
      final map = <String, dynamic>{'id': 'uuid-456'};

      final wallpaper = Wallpaper.fromMap(map);

      expect(wallpaper.wallhavenId, '');
      expect(wallpaper.urlFull, '');
      expect(wallpaper.urlThumb, '');
      expect(wallpaper.resolution, '');
      expect(wallpaper.width, 0);
      expect(wallpaper.height, 0);
      expect(wallpaper.fileSize, 0);
      expect(wallpaper.primaryColor, '#000000');
      expect(wallpaper.category, 'general');
      expect(wallpaper.sourceQuery, '');
    });

    test('parses invalid date gracefully', () {
      final map = {'id': 'uuid-789', 'created_at': 'not-a-date'};

      final wallpaper = Wallpaper.fromMap(map);
      expect(wallpaper.createdAt, isA<DateTime>());
    });
  });

  group('Wallpaper.aspectRatio', () {
    test('calculates 16:9 ratio', () {
      final wallpaper = Wallpaper(
        id: '1',
        wallhavenId: 'abc',
        urlFull: '',
        urlThumb: '',
        resolution: '1920x1080',
        width: 1920,
        height: 1080,
        fileSize: 0,
        primaryColor: '#000000',
        category: 'general',
        sourceQuery: 'desktop',
        createdAt: DateTime.now(),
      );

      expect(wallpaper.aspectRatio, closeTo(16 / 9, 0.01));
    });

    test('calculates 9:16 portrait ratio', () {
      final wallpaper = Wallpaper(
        id: '2',
        wallhavenId: 'def',
        urlFull: '',
        urlThumb: '',
        resolution: '1080x1920',
        width: 1080,
        height: 1920,
        fileSize: 0,
        primaryColor: '#000000',
        category: 'general',
        sourceQuery: 'mobile',
        createdAt: DateTime.now(),
      );

      expect(wallpaper.aspectRatio, closeTo(9 / 16, 0.01));
    });

    test('calculates 21:9 ultrawide ratio', () {
      final wallpaper = Wallpaper(
        id: '3',
        wallhavenId: 'ghi',
        urlFull: '',
        urlThumb: '',
        resolution: '3440x1440',
        width: 3440,
        height: 1440,
        fileSize: 0,
        primaryColor: '#000000',
        category: 'general',
        sourceQuery: 'desktop',
        createdAt: DateTime.now(),
      );

      expect(wallpaper.aspectRatio, closeTo(3440 / 1440, 0.01));
    });

    test('handles zero height without division error', () {
      final wallpaper = Wallpaper(
        id: '4',
        wallhavenId: 'jkl',
        urlFull: '',
        urlThumb: '',
        resolution: '0x0',
        width: 0,
        height: 0,
        fileSize: 0,
        primaryColor: '#000000',
        category: 'general',
        sourceQuery: '',
        createdAt: DateTime.now(),
      );

      // 0 / 0 in Dart = NaN (not an exception), but we should be aware
      expect(
        wallpaper.aspectRatio.isNaN || wallpaper.aspectRatio.isInfinite,
        true,
      );
    });
  });

  group('Wallpaper.formattedFileSize', () {
    test('formats bytes to KB', () {
      final wallpaper = Wallpaper(
        id: '1',
        wallhavenId: '',
        urlFull: '',
        urlThumb: '',
        resolution: '',
        width: 0,
        height: 0,
        fileSize: 512000,
        primaryColor: '#000000',
        category: 'general',
        sourceQuery: '',
        createdAt: DateTime.now(),
      );
      expect(wallpaper.formattedFileSize, '500.0 KB');
    });

    test('formats bytes to MB', () {
      final wallpaper = Wallpaper(
        id: '1',
        wallhavenId: '',
        urlFull: '',
        urlThumb: '',
        resolution: '',
        width: 0,
        height: 0,
        fileSize: 4200000,
        primaryColor: '#000000',
        category: 'general',
        sourceQuery: '',
        createdAt: DateTime.now(),
      );
      expect(wallpaper.formattedFileSize, '4.0 MB');
    });

    test('formats exactly 1MB', () {
      final wallpaper = Wallpaper(
        id: '1',
        wallhavenId: '',
        urlFull: '',
        urlThumb: '',
        resolution: '',
        width: 0,
        height: 0,
        fileSize: 1048576,
        primaryColor: '#000000',
        category: 'general',
        sourceQuery: '',
        createdAt: DateTime.now(),
      );
      expect(wallpaper.formattedFileSize, '1.0 MB');
    });

    test('formats zero bytes', () {
      final wallpaper = Wallpaper(
        id: '1',
        wallhavenId: '',
        urlFull: '',
        urlThumb: '',
        resolution: '',
        width: 0,
        height: 0,
        fileSize: 0,
        primaryColor: '#000000',
        category: 'general',
        sourceQuery: '',
        createdAt: DateTime.now(),
      );
      expect(wallpaper.formattedFileSize, '0.0 KB');
    });
  });

  group('Wallpaper.fromWallhavenMap', () {
    test('parses all fields from Wallhaven API response', () {
      final map = {
        'id': '94x38z',
        'path': 'https://w.wallhaven.cc/full/94/wallhaven-94x38z.jpg',
        'resolution': '6742x3534',
        'dimension_x': 6742,
        'dimension_y': 3534,
        'file_size': 5070446,
        'category': 'anime',
        'colors': ['#abbcda', '#424153', '#66cccc'],
        'thumbs': {
          'large': 'https://th.wallhaven.cc/lg/94/94x38z.jpg',
          'original': 'https://th.wallhaven.cc/orig/94/94x38z.jpg',
          'small': 'https://th.wallhaven.cc/small/94/94x38z.jpg',
        },
        'created_at': '2018-10-31 01:23:10',
      };

      final wallpaper = Wallpaper.fromWallhavenMap(map);

      expect(wallpaper.wallhavenId, '94x38z');
      expect(
        wallpaper.urlFull,
        'https://w.wallhaven.cc/full/94/wallhaven-94x38z.jpg',
      );
      expect(wallpaper.urlThumb, 'https://th.wallhaven.cc/small/94/94x38z.jpg');
      expect(wallpaper.resolution, '6742x3534');
      expect(wallpaper.width, 6742);
      expect(wallpaper.height, 3534);
      expect(wallpaper.fileSize, 5070446);
      expect(wallpaper.primaryColor, '#abbcda');
      expect(wallpaper.category, 'anime');
      expect(wallpaper.sourceQuery, '');
    });

    test('uses first color from colors array', () {
      final map = {
        'id': 'abc',
        'path': 'https://example.com/full.jpg',
        'resolution': '1920x1080',
        'dimension_x': 1920,
        'dimension_y': 1080,
        'file_size': 1000000,
        'category': 'general',
        'colors': ['#ff0000', '#00ff00', '#0000ff'],
        'thumbs': {
          'large': '',
          'original': 'https://example.com/thumb.jpg',
          'small': '',
        },
      };

      final wallpaper = Wallpaper.fromWallhavenMap(map);
      expect(wallpaper.primaryColor, '#ff0000');
    });

    test('defaults primaryColor to black when colors empty', () {
      final map = {
        'id': 'abc',
        'path': 'https://example.com/full.jpg',
        'resolution': '1920x1080',
        'dimension_x': 1920,
        'dimension_y': 1080,
        'file_size': 1000000,
        'category': 'general',
        'colors': <String>[],
        'thumbs': {
          'large': '',
          'original': 'https://example.com/thumb.jpg',
          'small': '',
        },
      };

      final wallpaper = Wallpaper.fromWallhavenMap(map);
      expect(wallpaper.primaryColor, '#000000');
    });

    test('defaults primaryColor to black when colors missing', () {
      final map = {
        'id': 'abc',
        'path': 'https://example.com/full.jpg',
        'resolution': '1920x1080',
        'dimension_x': 1920,
        'dimension_y': 1080,
        'file_size': 1000000,
        'category': 'general',
        'thumbs': {
          'large': '',
          'original': 'https://example.com/thumb.jpg',
          'small': '',
        },
      };

      final wallpaper = Wallpaper.fromWallhavenMap(map);
      expect(wallpaper.primaryColor, '#000000');
    });

    test('generates UUID from wallhaven id', () {
      final map = {
        'id': 'abc123',
        'path': 'https://example.com/full.jpg',
        'resolution': '1920x1080',
        'dimension_x': 1920,
        'dimension_y': 1080,
        'file_size': 1000000,
        'category': 'general',
        'colors': <String>['#000000'],
        'thumbs': {
          'large': '',
          'original': 'https://example.com/thumb.jpg',
          'small': '',
        },
      };

      final wallpaper = Wallpaper.fromWallhavenMap(map);
      expect(wallpaper.id, isNotEmpty);
      expect(wallpaper.id, isNot('abc123'));
    });

    test('handles missing thumbs gracefully', () {
      final map = {
        'id': 'abc',
        'path': 'https://example.com/full.jpg',
        'resolution': '1920x1080',
        'dimension_x': 1920,
        'dimension_y': 1080,
        'file_size': 1000000,
        'category': 'general',
        'colors': <String>['#000000'],
      };

      final wallpaper = Wallpaper.fromWallhavenMap(map);
      expect(wallpaper.urlThumb, isEmpty);
    });

    test('handles zero dimensions', () {
      final map = {
        'id': 'abc',
        'path': 'https://example.com/full.jpg',
        'resolution': '0x0',
        'dimension_x': 0,
        'dimension_y': 0,
        'file_size': 0,
        'category': 'general',
        'colors': <String>['#000000'],
        'thumbs': {
          'large': '',
          'original': 'https://example.com/thumb.jpg',
          'small': '',
        },
      };

      final wallpaper = Wallpaper.fromWallhavenMap(map);
      expect(wallpaper.width, 0);
      expect(wallpaper.height, 0);
    });

    test('aspectRatio works with parsed Wallhaven data', () {
      final map = {
        'id': 'abc',
        'path': 'https://example.com/full.jpg',
        'resolution': '1920x1080',
        'dimension_x': 1920,
        'dimension_y': 1080,
        'file_size': 1000000,
        'category': 'general',
        'colors': <String>['#000000'],
        'thumbs': {
          'large': '',
          'original': 'https://example.com/thumb.jpg',
          'small': '',
        },
      };

      final wallpaper = Wallpaper.fromWallhavenMap(map);
      expect(wallpaper.aspectRatio, closeTo(16 / 9, 0.01));
    });
  });
}
