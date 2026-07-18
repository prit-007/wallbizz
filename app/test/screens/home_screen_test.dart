import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vivek_app/screens/home_screen.dart';
import 'package:vivek_app/screens/search_screen.dart';

void main() {
  setUpAll(() async {
    try {
      await dotenv.load();
    } catch (_) {}
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
      home: SizedBox(
        width: 400,
        height: 800,
        child: const HomeScreen(),
      ),
    );
  }

  group('HomeScreen search bar', () {
    testWidgets('renders search bar with placeholder text', (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.byKey(const Key('search_bar')), findsOneWidget);
      expect(find.text('Search wallpapers...'), findsOneWidget);
    });

    testWidgets('renders search icon in search bar', (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('search bar has rounded container style', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const Key('search_bar')),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(24));
    });

    testWidgets('tapping search bar navigates to SearchScreen',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byKey(const Key('search_bar')));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('back button from SearchScreen returns to HomeScreen',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byKey(const Key('search_bar')));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsNothing);
      expect(find.byKey(const Key('search_bar')), findsOneWidget);
    });

    testWidgets('bottom navigation bar still renders', (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('My Collection'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('search bar is a GestureDetector', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final searchBar = find.byKey(const Key('search_bar'));
      expect(searchBar, findsOneWidget);

      final searchBarFinder = searchBar.evaluate().first.widget;
      expect(searchBarFinder, isA<GestureDetector>());
    });
  });
}
