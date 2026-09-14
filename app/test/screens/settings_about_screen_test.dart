import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallbizz/config/theme_config.dart';
import 'package:wallbizz/screens/settings_about_screen.dart';

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
    tempDir = Directory.systemTemp.createTempSync('settings_about_test_');
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

  Widget buildTestApp() {
    return const MaterialApp(home: SettingsAboutScreen());
  }

  group('SettingsAboutScreen', () {
    testWidgets('renders the Manifesto app bar title', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Manifesto'), findsOneWidget);
    });

    testWidgets('renders Wallbizz title', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Wallbizz'), findsOneWidget);
    });

    testWidgets('renders THE VISION section', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('THE VISION'), findsOneWidget);
    });

    testWidgets('renders tagline text', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.textContaining(
          'Premium curated wallpapers, delivered with precision',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders version text with dash placeholder', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('EDITION'), findsOneWidget);
    });

    testWidgets('is a StatefulWidget', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 1));
      final state = tester.state<State>(find.byType(SettingsAboutScreen));
      expect(state, isNotNull);
    });
  });
}
