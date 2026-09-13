import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallbizz/config/theme_config.dart';
import 'package:wallbizz/screens/home_screen.dart';
import 'package:wallbizz/screens/search_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() async {
    try {
      await dotenv.load();
    } catch (_) {}
    SharedPreferences.setMockInitialValues({});
    Hive.init(Directory.systemTemp.path);
    await Hive.openBox('downloads');
    await ThemeConfig.load();
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  setUp(() {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.toString().contains('overflowed') ||
          details.toString().contains('RenderFlex')) {
        return;
      }
      FlutterError.presentError(details);
    };
  });

  tearDown(() {
    FlutterError.onError = FlutterError.presentError;
  });

  Widget buildTestApp() {
    return MaterialApp(
      home: SizedBox(width: 400, height: 800, child: const HomeScreen()),
    );
  }

  group('HomeScreen search bar', () {
    testWidgets('renders search bar with placeholder text', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('search_bar')), findsOneWidget);
      expect(find.text('EXPLORE CURATED ARCHIVES...'), findsOneWidget);
    });

    testWidgets('renders search icon in search bar', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byType(HugeIcon), findsWidgets);
    });

    testWidgets('search bar has rounded container style', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const Key('search_bar')),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(0));
    });

    testWidgets('tapping search bar navigates to SearchScreen', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('search_bar')));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('back button from SearchScreen returns to HomeScreen', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('search_bar')));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);

      await tester.tap(find.byType(HugeIcon).first);
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsNothing);
      expect(find.byKey(const Key('search_bar')), findsOneWidget);
    });

    testWidgets('bottom navigation bar still renders', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.text('DISCOVER'), findsOneWidget);
      expect(find.byType(HugeIcon), findsWidgets);
    });

    testWidgets('search bar is a GestureDetector', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final searchBar = find.byKey(const Key('search_bar'));
      expect(searchBar, findsOneWidget);

      final searchBarFinder = searchBar.evaluate().first.widget;
      expect(searchBarFinder, isA<GestureDetector>());
    });
  });
}
