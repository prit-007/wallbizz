import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallbizz/config/theme_config.dart';
import 'package:wallbizz/screens/downloads_screen.dart';

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
    tempDir = Directory.systemTemp.createTempSync('downloads_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('downloads');
    await ThemeConfig.load();
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  tearDown(() async {
    await Hive.box('downloads').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  Widget buildTestApp() {
    return const MaterialApp(home: Scaffold(body: DownloadsScreen()));
  }

  group('DownloadsScreen', () {
    testWidgets('renders the VAULT title', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('VAULT'), findsOneWidget);
    });

    testWidgets('renders empty state when no downloads', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('NO DOWNLOADS YET'), findsOneWidget);
    });

    testWidgets('renders empty state description text', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.textContaining('Tap the download button on any wallpaper'),
        findsOneWidget,
      );
    });

    testWidgets('renders ITEMS counter', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('ITEMS'), findsOneWidget);
    });

    testWidgets('renders storage size indicator', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('KB'), findsOneWidget);
    });

    testWidgets('renders DownloadsScreen as StatefulWidget', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 1));

      final state = tester.state<State>(find.byType(DownloadsScreen));
      expect(state, isNotNull);
    });
  });
}
