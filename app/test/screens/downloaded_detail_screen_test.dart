import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallbizz/config/theme_config.dart';
import 'package:wallbizz/models/downloaded_wallpaper.dart';
import 'package:wallbizz/screens/downloaded_detail_screen.dart';

DownloadedWallpaper createTestDownloadedWallpaper() {
  return DownloadedWallpaper(
    wallhavenId: 'test-dl-1',
    localPath: '/tmp/test-dl-1.jpg',
    urlFull: 'https://w.wallhaven.cc/full/test/wallhaven-test-dl-1.jpg',
    urlThumb: 'https://th.wallhaven.cc/small/test/th-test-dl-1.jpg',
    sourceQuery: 'nature',
    category: 'general',
    primaryColor: '#33FF57',
    resolution: '2560x1440',
    width: 2560,
    height: 1440,
    fileSize: 3000000,
    downloadedAt: DateTime(2024, 6, 15),
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
    tempDir = Directory.systemTemp.createTempSync('downloaded_detail_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('downloads');
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

  Widget buildTestApp({DownloadedWallpaper? wallpaper}) {
    return MaterialApp(
      home: DownloadedDetailScreen(
        downloadedWallpaper: wallpaper ?? createTestDownloadedWallpaper(),
      ),
    );
  }

  group('DownloadedDetailScreen', () {
    testWidgets('renders the detail screen', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(DownloadedDetailScreen), findsOneWidget);
    });

    testWidgets('receives downloaded wallpaper with correct data', (
      tester,
    ) async {
      final wallpaper = createTestDownloadedWallpaper();
      await tester.pumpWidget(buildTestApp(wallpaper: wallpaper));
      await tester.pump(const Duration(seconds: 2));

      final screen = tester.widget<DownloadedDetailScreen>(
        find.byType(DownloadedDetailScreen),
      );
      expect(screen.downloadedWallpaper.wallhavenId, 'test-dl-1');
      expect(screen.downloadedWallpaper.resolution, '2560x1440');
    });

    testWidgets('renders back button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(HugeIcon), findsWidgets);
    });

    testWidgets('renders Downloaded badge', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Downloaded'), findsOneWidget);
    });

    testWidgets('renders Set as Wallpaper button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Set as Wallpaper'), findsOneWidget);
    });
  });
}
