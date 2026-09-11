import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/widgets/dynamic_theme.dart';

Widget _wrapInApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('DynamicTheme', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          const DynamicTheme(primaryColor: '#FF0000', child: Text('Hello')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('has gradient background from hex', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          const DynamicTheme(primaryColor: '#FF0000', child: SizedBox()),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
      final gradient = decoration.gradient as RadialGradient;
      expect(gradient.colors.length, 3);
    });

    testWidgets('uses AnimatedContainer for transition', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          const DynamicTheme(primaryColor: '#00FF00', child: SizedBox()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('handles different hex colors', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          const DynamicTheme(primaryColor: '#66cccc', child: Text('Test')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
    });

    testWidgets('handles black color', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          const DynamicTheme(primaryColor: '#000000', child: Text('Dark')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dark'), findsOneWidget);
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
    });

    testWidgets('handles white color', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          const DynamicTheme(primaryColor: '#FFFFFF', child: Text('Light')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Light'), findsOneWidget);
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      final gradient = decoration.gradient as RadialGradient;
      expect(gradient.colors.length, 3);
    });
  });
}
