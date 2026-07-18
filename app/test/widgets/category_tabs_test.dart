import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vivek_app/widgets/category_tabs.dart';

Widget _wrapInApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 200,
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('CategoryTabs', () {
    testWidgets('renders all 5 categories', (tester) async {
      await tester.pumpWidget(_wrapInApp(
        CategoryTabs(
          selectedCategory: 'trending',
          onCategorySelected: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('Trending'), findsOneWidget);
      expect(find.text('Anime'), findsOneWidget);
      expect(find.text('AMOLED'), findsOneWidget);
      expect(find.text('Desktop'), findsOneWidget);
      expect(find.text('Mobile'), findsOneWidget);
    });

    testWidgets('renders all 5 icons', (tester) async {
      await tester.pumpWidget(_wrapInApp(
        CategoryTabs(
          selectedCategory: 'trending',
          onCategorySelected: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('\u{1F525}'), findsOneWidget);
      expect(find.text('\u{1F338}'), findsOneWidget);
      expect(find.text('\u2B1B'), findsOneWidget);
      expect(find.text('\u{1F5A5}'), findsOneWidget);
      expect(find.text('\u{1F4F1}'), findsOneWidget);
    });

    testWidgets('calls onCategorySelected when category is tapped', (tester) async {
      String? selected;
      await tester.pumpWidget(_wrapInApp(
        CategoryTabs(
          selectedCategory: 'trending',
          onCategorySelected: (cat) => selected = cat,
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Anime'));
      expect(selected, 'anime');
    });

    testWidgets('calls callback with correct value for each category', (tester) async {
      String? selected;
      await tester.pumpWidget(_wrapInApp(
        CategoryTabs(
          selectedCategory: 'trending',
          onCategorySelected: (cat) => selected = cat,
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('AMOLED'));
      expect(selected, 'amoled');

      await tester.tap(find.text('Desktop'));
      expect(selected, 'desktop');

      await tester.tap(find.text('Mobile'));
      expect(selected, 'mobile');

      await tester.tap(find.text('Trending'));
      expect(selected, 'trending');
    });

    testWidgets('is a horizontal ListView', (tester) async {
      await tester.pumpWidget(_wrapInApp(
        CategoryTabs(
          selectedCategory: 'trending',
          onCategorySelected: (_) {},
        ),
      ));
      await tester.pump();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('shows 5 AnimatedContainers for categories', (tester) async {
      await tester.pumpWidget(_wrapInApp(
        CategoryTabs(
          selectedCategory: 'trending',
          onCategorySelected: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.byType(AnimatedContainer), findsNWidgets(5));
    });

    testWidgets('renders when no category is selected initially', (tester) async {
      await tester.pumpWidget(_wrapInApp(
        CategoryTabs(
          selectedCategory: '',
          onCategorySelected: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('Trending'), findsOneWidget);
      expect(find.text('Anime'), findsOneWidget);
    });

    testWidgets('handles rapid taps without errors', (tester) async {
      final selections = <String>[];
      await tester.pumpWidget(_wrapInApp(
        CategoryTabs(
          selectedCategory: 'trending',
          onCategorySelected: (cat) => selections.add(cat),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Anime'));
      await tester.tap(find.text('AMOLED'));
      await tester.tap(find.text('Desktop'));
      await tester.tap(find.text('Mobile'));
      await tester.tap(find.text('Trending'));

      expect(selections, ['anime', 'amoled', 'desktop', 'mobile', 'trending']);
    });
  });
}
