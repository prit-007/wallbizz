import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallbizz/widgets/connectivity_banner.dart';

class FakeConnectivity extends Fake implements Connectivity {
  final List<ConnectivityResult> _results;

  FakeConnectivity([this._results = const [ConnectivityResult.wifi]]);

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _results;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.fromIterable([]);
}

Widget _wrapInApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 400, height: 800, child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityBanner', () {
    testWidgets('renders child widget when online', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(const ConnectivityBanner(child: Text('Child Content'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Child Content'), findsOneWidget);
    });

    testWidgets('does not show offline banner when online', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(const ConnectivityBanner(child: Text('Content'))),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off), findsNothing);
      expect(find.text('You are offline'), findsNothing);
    });

    testWidgets('renders Column with two children', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(const ConnectivityBanner(child: Text('Below'))),
      );
      await tester.pumpAndSettle();

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.children.length, 2);
    });

    testWidgets('contains AnimatedSize for banner transition', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(const ConnectivityBanner(child: Text('Content'))),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedSize), findsOneWidget);
    });

    testWidgets('child is wrapped in Expanded', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(const ConnectivityBanner(child: Text('Wrapped'))),
      );
      await tester.pumpAndSettle();

      final expanded = find.byType(Expanded);
      expect(expanded, findsOneWidget);

      final expandedWidget = tester.widget<Expanded>(expanded);
      final child = expandedWidget.child;
      expect(child, isA<Text>());
    });
  });
}
