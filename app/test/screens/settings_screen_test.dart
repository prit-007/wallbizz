import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vivek_app/config/theme_config.dart';
import 'package:vivek_app/screens/settings_screen.dart';

Widget _wrapInApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ThemeConfig.load();
  });

  group('SettingsScreen', () {
    testWidgets('renders Settings title', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders Dark Mode toggle', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('dark mode is on by default', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchWidget.value, true);
    });

    testWidgets('can toggle dark mode off', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchWidget.value, false);
    });

    testWidgets('toggle persists to SharedPreferences', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dark_mode'), false);
    });

    testWidgets('has SwitchListTile for Dark Mode', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('renders STORAGE section', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('STORAGE'), findsOneWidget);
    });

    testWidgets('renders storage options', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Pictures'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('App Storage'), findsOneWidget);
    });

    testWidgets('toggles back and forth', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      // Toggle off
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      var sw = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(sw.value, false);

      // Toggle on
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      sw = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(sw.value, true);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dark_mode'), true);
    });

    testWidgets('loads saved dark_mode preference', (tester) async {
      SharedPreferences.setMockInitialValues({'dark_mode': false});
      await ThemeConfig.load();

      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchWidget.value, false);
    });

    testWidgets('description text is present', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Use dark theme throughout the app'), findsOneWidget);
    });
  });
}
