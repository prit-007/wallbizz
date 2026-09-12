import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wallbizz/widgets/specs_card.dart';
import 'package:wallbizz/models/wallpaper.dart';

Wallpaper _makeWallpaper({
  String resolution = '3840x2160',
  int fileSize = 4200000,
  String sourceQuery = 'anime',
}) {
  return Wallpaper(
    id: 'test-id',
    wallhavenId: 'abc',
    urlFull: 'https://example.com/full.jpg',
    urlThumb: 'https://example.com/thumb.jpg',
    resolution: resolution,
    width: 3840,
    height: 2160,
    fileSize: fileSize,
    primaryColor: '#1a1a2e',
    category: 'general',
    sourceQuery: sourceQuery,
    createdAt: DateTime(2024, 1, 15),
  );
}

Widget _wrapInApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('SpecsCard', () {
    testWidgets('renders resolution with × separator', (tester) async {
      final wallpaper = _makeWallpaper(resolution: '3840x2160');
      await tester.pumpWidget(_wrapInApp(SpecsCard(wallpaper: wallpaper)));
      await tester.pump();

      expect(find.text('3840 × 2160'), findsWidgets);
    });

    testWidgets('renders different resolution correctly', (tester) async {
      final wallpaper = _makeWallpaper(resolution: '2560x1440');
      await tester.pumpWidget(_wrapInApp(SpecsCard(wallpaper: wallpaper)));
      await tester.pump();

      expect(find.text('2560 × 1440'), findsOneWidget);
    });

    testWidgets('renders formatted file size in MB', (tester) async {
      final wallpaper = _makeWallpaper(fileSize: 4200000);
      await tester.pumpWidget(_wrapInApp(SpecsCard(wallpaper: wallpaper)));
      await tester.pump();

      expect(find.text('4.0 MB'), findsOneWidget);
    });

    testWidgets('renders formatted file size in KB', (tester) async {
      final wallpaper = _makeWallpaper(fileSize: 512000);
      await tester.pumpWidget(_wrapInApp(SpecsCard(wallpaper: wallpaper)));
      await tester.pump();

      expect(find.text('500.0 KB'), findsOneWidget);
    });

    testWidgets('renders category chip in uppercase', (tester) async {
      final wallpaper = _makeWallpaper(sourceQuery: 'amoled');
      await tester.pumpWidget(_wrapInApp(SpecsCard(wallpaper: wallpaper)));
      await tester.pump();

      expect(find.text('AMOLED'), findsOneWidget);
    });

    testWidgets('renders different category chip', (tester) async {
      final wallpaper = _makeWallpaper(sourceQuery: 'desktop');
      await tester.pumpWidget(_wrapInApp(SpecsCard(wallpaper: wallpaper)));
      await tester.pump();

      expect(find.text('DESKTOP'), findsOneWidget);
    });

    testWidgets('has ClipRRect for rounded corners', (tester) async {
      final wallpaper = _makeWallpaper();
      await tester.pumpWidget(_wrapInApp(SpecsCard(wallpaper: wallpaper)));
      await tester.pump();

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('has BackdropFilter for glassmorphism', (tester) async {
      final wallpaper = _makeWallpaper();
      await tester.pumpWidget(_wrapInApp(SpecsCard(wallpaper: wallpaper)));
      await tester.pump();

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('renders all three info sections', (tester) async {
      final wallpaper = _makeWallpaper(
        resolution: '1920x1080',
        fileSize: 2000000,
        sourceQuery: 'mobile',
      );
      await tester.pumpWidget(_wrapInApp(SpecsCard(wallpaper: wallpaper)));
      await tester.pump();

      expect(find.text('1920 × 1080'), findsOneWidget);
      expect(find.text('1.9 MB'), findsOneWidget);
      expect(find.text('MOBILE'), findsOneWidget);
    });

    testWidgets('renders tiny file size', (tester) async {
      final wallpaper = _makeWallpaper(fileSize: 50000);
      await tester.pumpWidget(_wrapInApp(SpecsCard(wallpaper: wallpaper)));
      await tester.pump();

      expect(find.text('48.8 KB'), findsOneWidget);
    });
  });
}
