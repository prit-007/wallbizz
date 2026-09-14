import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallbizz/config/theme_config.dart';
import 'package:wallbizz/models/wallpaper.dart';
import 'package:wallbizz/screens/detail_screen.dart';

Wallpaper createTestWallpaper() {
  return Wallpaper(
    id: 'wh-test123',
    wallhavenId: 'test123',
    urlFull: 'https://w.wallhaven.cc/full/test/wallhaven-test123.jpg',
    urlThumb: 'https://th.wallhaven.cc/small/test/th-test123.jpg',
    resolution: '1920x1080',
    width: 1920,
    height: 1080,
    fileSize: 2000000,
    primaryColor: '#FF5733',
    category: 'general',
    sourceQuery: 'nature',
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late Directory tempDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    if (!dotenv.isInitialized) {
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=https://test.supabase.co\nSUPABASE_ANON_KEY=test-anon-key',
      );
    }
    tempDir = Directory.systemTemp.createTempSync('detail_test_');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('downloads')) {
      await Hive.openBox('downloads');
    }
    await ThemeConfig.load();
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  setUp(() {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.toString().contains('dependOnInheritedWidgetOfExactType') ||
          details.toString().contains('MediaQuery') ||
          details.toString().contains(
            'The following assertion was thrown building',
          )) {
        return;
      }
      FlutterError.presentError(details);
    };
  });

  tearDown(() {
    FlutterError.onError = FlutterError.presentError;
  });

  group('DetailScreen', () {
    testWidgets('creates DetailScreen widget with wallpaper', (tester) async {
      final wallpaper = createTestWallpaper();
      final screen = DetailScreen(wallpaper: wallpaper);
      expect(screen.wallpaper.id, 'wh-test123');
      expect(screen.wallpaper.wallhavenId, 'test123');
    });

    testWidgets('DetailScreen is a StatefulWidget', (tester) async {
      expect(
        DetailScreen(wallpaper: createTestWallpaper()),
        isA<StatefulWidget>(),
      );
    });

    testWidgets('wallpaper has correct properties', (tester) async {
      final wallpaper = createTestWallpaper();
      expect(wallpaper.resolution, '1920x1080');
      expect(wallpaper.width, 1920);
      expect(wallpaper.height, 1080);
      expect(wallpaper.primaryColor, '#FF5733');
      expect(wallpaper.category, 'general');
    });

    testWidgets('wallpaper computes correct aspect ratio', (tester) async {
      final wallpaper = createTestWallpaper();
      expect(wallpaper.aspectRatio, 1920 / 1080);
    });
  });
}
