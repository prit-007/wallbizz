import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallbizz/config/theme_config.dart';
import 'package:wallbizz/screens/wishlist_screen.dart';

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
    tempDir = Directory.systemTemp.createTempSync('wishlist_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('downloads');
    await Hive.openBox('wishlists');
    await Hive.openBox('moodboards');
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
    return const MaterialApp(home: Scaffold(body: WishlistScreen()));
  }

  group('WishlistScreen', () {
    testWidgets('renders the guest view when not logged in', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('MEMBERS ONLY'), findsOneWidget);
    });

    testWidgets('renders sign in prompt text', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Sign in to sync and view your curated collection'),
        findsOneWidget,
      );
    });

    testWidgets('renders SIGN IN NOW button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('SIGN IN NOW'), findsOneWidget);
    });

    testWidgets('renders WishlistScreen as StatefulWidget', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final state = tester.state<State>(find.byType(WishlistScreen));
      expect(state, isNotNull);
    });

    testWidgets('does not render ARCHIVE title when not logged in', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('ARCHIVE'), findsNothing);
    });

    testWidgets('renders sign in button as ElevatedButton', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button, isNotNull);
    });
  });
}
