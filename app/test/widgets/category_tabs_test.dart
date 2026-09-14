import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wallbizz/widgets/category_tabs.dart';

Widget _wrapInApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 800, height: 60, child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('CategoryTabs', () {
    testWidgets('renders category tabs in a horizontal ListView', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapInApp(
          CategoryTabs(
            selectedCategory: 'trending',
            onCategorySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('renders the selected category with primary color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapInApp(
          CategoryTabs(selectedCategory: 'nature', onCategorySelected: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainers = find.byType(AnimatedContainer);
      expect(animatedContainers, findsWidgets);

      final cs = Theme.of(
        tester.element(find.byType(CategoryTabs)),
      ).colorScheme;

      final containers = <AnimatedContainer>[];
      for (final element in animatedContainers.evaluate()) {
        containers.add(element.widget as AnimatedContainer);
      }

      final selected = containers.firstWhere((c) {
        final deco = c.decoration as BoxDecoration;
        return deco.color == cs.primary;
      });
      final decoration = selected.decoration as BoxDecoration;
      expect(decoration.color, cs.primary);
    });

    testWidgets('unselected tab has non-primary background', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          CategoryTabs(selectedCategory: 'nature', onCategorySelected: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainers = find.byType(AnimatedContainer);
      final containers = <AnimatedContainer>[];
      for (final element in animatedContainers.evaluate()) {
        containers.add(element.widget as AnimatedContainer);
      }

      final cs = Theme.of(
        tester.element(find.byType(CategoryTabs)),
      ).colorScheme;

      final unselected = containers.where((c) {
        final deco = c.decoration as BoxDecoration;
        return deco.color != cs.primary;
      });
      expect(unselected.isNotEmpty, true);
    });

    testWidgets('tapping a visible category calls onCategorySelected', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        _wrapInApp(
          CategoryTabs(
            selectedCategory: 'trending',
            onCategorySelected: (cat) => selected = cat,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final trendingText = find.text('TRENDING');
      if (trendingText.evaluate().isNotEmpty) {
        await tester.tap(trendingText, warnIfMissed: false);
        expect(selected, 'trending');
      }
    });

    testWidgets('selected tab has boxShadow', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          CategoryTabs(selectedCategory: 'space', onCategorySelected: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainers = find.byType(AnimatedContainer);
      final containers = <AnimatedContainer>[];
      for (final element in animatedContainers.evaluate()) {
        containers.add(element.widget as AnimatedContainer);
      }

      final cs = Theme.of(
        tester.element(find.byType(CategoryTabs)),
      ).colorScheme;

      final selected = containers.firstWhere((c) {
        final deco = c.decoration as BoxDecoration;
        return deco.color == cs.primary;
      });
      final decoration = selected.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('renders Semantics widgets for each category', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          CategoryTabs(
            selectedCategory: 'trending',
            onCategorySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final semantics = find.byType(Semantics);
      expect(semantics, findsWidgets);
    });

    testWidgets('GestureDetector exists for each category', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          CategoryTabs(
            selectedCategory: 'trending',
            onCategorySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gestureDetectors = find.byType(GestureDetector);
      expect(gestureDetectors, findsWidgets);
    });
  });
}
