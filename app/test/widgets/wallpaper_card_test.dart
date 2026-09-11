import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/widgets/wallpaper_card.dart';
import 'package:vivek_app/models/wallpaper.dart';

Wallpaper _makeWallpaper({
  String id = 'test-id',
  String resolution = '1920x1080',
  int width = 1920,
  int height = 1080,
  String urlThumb = 'https://th.wallhaven.cc/orig/test.jpg',
}) {
  return Wallpaper(
    id: id,
    wallhavenId: 'abc',
    urlFull: 'https://w.wallhaven.cc/full/test.jpg',
    urlThumb: urlThumb,
    resolution: resolution,
    width: width,
    height: height,
    fileSize: 2000000,
    primaryColor: '#1a1a2e',
    category: 'general',
    sourceQuery: 'trending',
    createdAt: DateTime(2024, 1, 15),
  );
}

Widget _wrapInApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 400,
        height: 600,
        child: child,
      ),
    ),
  );
}

void main() {
  group('WallpaperCard', () {
    testWidgets('renders resolution badge', (tester) async {
      final wallpaper = _makeWallpaper(resolution: '3840x2160');
      await tester.pumpWidget(_wrapInApp(
        WallpaperCard(wallpaper: wallpaper),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('3840x2160'), findsOneWidget);
    });

    testWidgets('renders with default isWishlisted false', (tester) async {
      final wallpaper = _makeWallpaper();
      await tester.pumpWidget(_wrapInApp(
        WallpaperCard(
          wallpaper: wallpaper,
          onHeartTap: () {},
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('renders filled heart when isWishlisted is true', (tester) async {
      final wallpaper = _makeWallpaper();
      await tester.pumpWidget(_wrapInApp(
        WallpaperCard(
          wallpaper: wallpaper,
          onHeartTap: () {},
          isWishlisted: true,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('does not show heart icon when onHeartTap is null', (tester) async {
      final wallpaper = _makeWallpaper();
      await tester.pumpWidget(_wrapInApp(
        WallpaperCard(wallpaper: wallpaper),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.favorite_border), findsNothing);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      bool tapped = false;
      final wallpaper = _makeWallpaper();
      await tester.pumpWidget(_wrapInApp(
        WallpaperCard(
          wallpaper: wallpaper,
          onTap: () => tapped = true,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byType(WallpaperCard));
      expect(tapped, true);
    });

    testWidgets('calls onHeartTap when heart icon is tapped', (tester) async {
      bool heartTapped = false;
      final wallpaper = _makeWallpaper();
      await tester.pumpWidget(_wrapInApp(
        WallpaperCard(
          wallpaper: wallpaper,
          onHeartTap: () => heartTapped = true,
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byIcon(Icons.favorite_border));
      expect(heartTapped, true);
    });

    testWidgets('renders correct resolution for different wallpapers', (tester) async {
      final wp = _makeWallpaper(resolution: '2560x1440');
      await tester.pumpWidget(_wrapInApp(
        WallpaperCard(wallpaper: wp),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('2560x1440'), findsOneWidget);
    });

    testWidgets('renders ClipRRect for rounded corners', (tester) async {
      final wallpaper = _makeWallpaper();
      await tester.pumpWidget(_wrapInApp(
        WallpaperCard(wallpaper: wallpaper),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
      expect(clipRRect.borderRadius, BorderRadius.circular(18));
    });

    testWidgets('renders gradient overlay at bottom', (tester) async {
      final wallpaper = _makeWallpaper();
      await tester.pumpWidget(_wrapInApp(
        WallpaperCard(wallpaper: wallpaper),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      final positioned = find.byWidgetPredicate(
        (w) => w is Positioned && w.bottom == 0,
      );
      expect(positioned, findsOneWidget);
    });

    testWidgets('card has GestureDetector for taps', (tester) async {
      final wallpaper = _makeWallpaper();
      await tester.pumpWidget(_wrapInApp(
        WallpaperCard(
          wallpaper: wallpaper,
          onTap: () {},
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
