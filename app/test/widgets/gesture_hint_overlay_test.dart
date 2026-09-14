import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallbizz/widgets/gesture_hint_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GestureHintOverlay', () {
    testWidgets('does not show overlay when already shown before', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'gesture_hints_shown_v2': true});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const GestureHintOverlay(child: Text('Content')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('GESTURE GUIDE'), findsNothing);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('shows gesture guide heading on first visit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const GestureHintOverlay(child: Text('Content')),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('GESTURE GUIDE'), findsOneWidget);
    });

    testWidgets('dismisses overlay when tapped', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const GestureHintOverlay(child: Text('Content')),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('GESTURE GUIDE'), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).last, warnIfMissed: false);
      await tester.pump();

      expect(find.text('GESTURE GUIDE'), findsNothing);
    });

    testWidgets('child remains visible after overlay is dismissed', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const GestureHintOverlay(child: Text('Content')),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.tap(find.byType(GestureDetector).last, warnIfMissed: false);
      await tester.pump();

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('markShown persists to SharedPreferences', (tester) async {
      await GestureHintOverlay.markShown();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('gesture_hints_shown_v2'), true);
    });

    testWidgets('shouldShow returns true when not yet shown', (tester) async {
      final shouldShow = await GestureHintOverlay.shouldShow();
      expect(shouldShow, true);
    });

    testWidgets('shouldShow returns false after markShown', (tester) async {
      await GestureHintOverlay.markShown();
      final shouldShow = await GestureHintOverlay.shouldShow();
      expect(shouldShow, false);
    });
  });
}
