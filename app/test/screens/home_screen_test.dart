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
import 'package:wallbizz/widgets/staggered_grid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late Directory tempDir;

  setUpAll(() async {
    if (!dotenv.isInitialized) {
      try {
        await dotenv.load();
      } catch (_) {
        dotenv.testLoad(
          fileInput:
              'SUPABASE_URL=https://test.supabase.co\nSUPABASE_ANON_KEY=test-anon-key',
        );
      }
    }
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('home_test_');
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

  Widget buildTestApp({double width = 400, double height = 800}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: SizedBox(
          width: width,
          height: height,
          child: const HomeScreen(),
        ),
      ),
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

    testWidgets('search bar has container style', (tester) async {
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

  group('HomeScreen layout structure', () {
    testWidgets('uses CustomScrollView for home tab', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('contains SliverAppBar with pinned tabs', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final sliverAppBar = tester.widget<SliverAppBar>(
        find.byType(SliverAppBar),
      );
      expect(sliverAppBar.pinned, isTrue);
    });

    testWidgets('renders brand header text WALLBIZZ', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.text('WALLBIZZ'), findsOneWidget);
    });

    testWidgets('renders StaggeredGrid on home tab', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byType(StaggeredGrid), findsOneWidget);
    });

    testWidgets('category tabs render within SliverAppBar', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.text('TRENDING'), findsOneWidget);
    });

    testWidgets('scrolling does not lose category tabs', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final scrollView = find.byType(CustomScrollView);
      await tester.drag(scrollView, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('TRENDING'), findsOneWidget);
      expect(find.byType(StaggeredGrid), findsOneWidget);
    });
  });

  group('HomeScreen landscape layout', () {
    testWidgets('renders compact brand header in landscape mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(width: 800, height: 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('WALLBIZZ'), findsOneWidget);
      expect(find.byKey(const Key('search_bar')), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text('WALLBIZZ'));
      final style = textWidget.style!;
      expect(style.fontSize, 28.0);
    });

    testWidgets('hides accent bar in landscape compact mode', (tester) async {
      tester.view.physicalSize = const Size(800, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(width: 800, height: 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('WALLBIZZ'), findsOneWidget);

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(Column),
          matching: find.byType(Container),
        ),
      );
      final accentBar = containers.where((c) {
        final d = c.decoration;
        return d == null && c.color != null;
      });
      expect(accentBar.isEmpty, isTrue);
    });

    testWidgets('search bar renders in landscape compact mode', (tester) async {
      tester.view.physicalSize = const Size(800, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(width: 800, height: 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(const Key('search_bar')), findsOneWidget);
    });
  });
}
