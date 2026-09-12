import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallbizz/config/scroll_config.dart';

void main() {
  group('WallbizzScrollBehavior', () {
    testWidgets('applies custom scroll behavior to app', (tester) async {
      final behavior = WallbizzScrollBehavior();

      await tester.pumpWidget(
        MaterialApp(
          scrollBehavior: behavior,
          home: Scaffold(
            body: ListView(
              children: List.generate(
                50,
                (i) => ListTile(title: Text('Item $i')),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('does not show GlowingOverscrollIndicator', (tester) async {
      final behavior = WallbizzScrollBehavior();

      await tester.pumpWidget(
        MaterialApp(
          scrollBehavior: behavior,
          home: Scaffold(
            body: ListView(
              children: List.generate(
                20,
                (i) => ListTile(title: Text('Item $i')),
              ),
            ),
          ),
        ),
      );

      // Scroll to trigger overscroll
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      // No GlowingOverscrollIndicator should be present
      expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    });

    testWidgets('scroll view works normally with custom behavior', (
      tester,
    ) async {
      final behavior = WallbizzScrollBehavior();

      await tester.pumpWidget(
        MaterialApp(
          scrollBehavior: behavior,
          home: Scaffold(
            body: ListView(
              children: List.generate(
                10,
                (i) => ListTile(title: Text('Item $i')),
              ),
            ),
          ),
        ),
      );

      // Items should be visible
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 5'), findsOneWidget);

      // Scroll down
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();

      // More items should be visible after scrolling
      expect(find.text('Item 9'), findsOneWidget);
    });
  });
}
