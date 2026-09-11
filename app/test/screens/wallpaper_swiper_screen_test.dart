import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vivek_app/config/theme_config.dart';
import 'package:vivek_app/models/wallpaper.dart';
import 'package:vivek_app/screens/wallpaper_swiper_screen.dart';

Wallpaper _makeWallpaper({String id = 'test-id', String color = '#7B8CFF'}) {
  return Wallpaper(
    id: id,
    wallhavenId: 'wh-$id',
    urlFull: 'https://w.wallhaven.cc/full/test/wallhaven-$id.jpg',
    urlThumb: 'https://th.wallhaven.cc/sm/test/wallhaven-$id.jpg',
    resolution: '1920x1080',
    width: 1920,
    height: 1080,
    fileSize: 2000000,
    primaryColor: color,
    category: 'general',
    sourceQuery: 'trending',
    createdAt: DateTime(2024, 1, 15),
  );
}

Widget _wrapInApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'gesture_hints_shown': true});
    Hive.init(Directory.systemTemp.path);
    await Hive.openBox('downloads');
    await ThemeConfig.load();
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('WallpaperSwiperScreen', () {
    testWidgets('renders with single wallpaper', (tester) async {
      final wallpapers = [_makeWallpaper()];
      await tester.pumpWidget(
        _wrapInApp(WallpaperSwiperScreen(wallpapers: wallpapers)),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(WallpaperSwiperScreen), findsOneWidget);
    });

    testWidgets('shows page counter for multiple wallpapers', (tester) async {
      final wallpapers = [
        _makeWallpaper(id: '1'),
        _makeWallpaper(id: '2'),
        _makeWallpaper(id: '3'),
      ];
      await tester.pumpWidget(
        _wrapInApp(
          WallpaperSwiperScreen(wallpapers: wallpapers, initialIndex: 0),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('shows back button', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(WallpaperSwiperScreen(wallpapers: [_makeWallpaper()])),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('shows heart button', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(WallpaperSwiperScreen(wallpapers: [_makeWallpaper()])),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('shows download button', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(WallpaperSwiperScreen(wallpapers: [_makeWallpaper()])),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('DOWNLOAD WALLPAPER'), findsOneWidget);
    });

    testWidgets('initializes at correct page index', (tester) async {
      final wallpapers = [
        _makeWallpaper(id: '1'),
        _makeWallpaper(id: '2'),
        _makeWallpaper(id: '3'),
      ];
      await tester.pumpWidget(
        _wrapInApp(
          WallpaperSwiperScreen(wallpapers: wallpapers, initialIndex: 1),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('shows set as wallpaper button', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(WallpaperSwiperScreen(wallpapers: [_makeWallpaper()])),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(WallpaperSwiperScreen), findsOneWidget);
      expect(find.byIcon(Icons.dashboard_customize_rounded), findsOneWidget);
      expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
    });

    testWidgets('shows moodboard button', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(WallpaperSwiperScreen(wallpapers: [_makeWallpaper()])),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.dashboard_customize_rounded), findsOneWidget);
    });
  });
}
