import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallbizz/config/theme_config.dart';
import 'package:wallbizz/screens/settings_screen.dart';

Widget _wrapInApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    if (!dotenv.isInitialized) {
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=https://test.supabase.co\nSUPABASE_ANON_KEY=test-anon-key',
      );
    }
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ThemeConfig.load();
  });

  group('SettingsScreen', () {
    testWidgets('renders PREFERENCES title', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('PREFERENCES'), findsOneWidget);
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

      final switchWidget = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchWidget.value, true);
    });

    testWidgets('can toggle dark mode off', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
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

    testWidgets('renders DOWNLOAD LOCATION section', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('DOWNLOAD LOCATION'), findsOneWidget);
    });

    testWidgets('renders storage options', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Pictures'), findsOneWidget);
      expect(find.text('Downloads'), findsOneWidget);
      expect(find.text('App Storage'), findsOneWidget);
    });

    testWidgets('toggles back and forth', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      var sw = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(sw.value, false);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      sw = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(sw.value, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dark_mode'), true);
    });

    testWidgets('loads saved dark_mode preference', (tester) async {
      SharedPreferences.setMockInitialValues({'dark_mode': false});
      await ThemeConfig.load();

      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchWidget.value, false);
    });

    testWidgets('description text is present', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Use dark theme throughout the app'), findsOneWidget);
    });

    testWidgets('renders App Logs tile', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('App Logs'), findsOneWidget);
    });

    testWidgets('renders Check for Updates tile', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('Check for Updates'), findsOneWidget);
    });

    testWidgets('renders About Wallbizz tile', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('About Wallbizz'), findsOneWidget);
    });

    testWidgets('renders ABOUT section', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('renders PREFERENCES section', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('PREFERENCES'), findsOneWidget);
    });

    testWidgets('renders ACCOUNT section', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('ACCOUNT'), findsOneWidget);
    });

    testWidgets('App Logs tile navigates to logs screen', (tester) async {
      await tester.pumpWidget(_wrapInApp(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('App Logs'));
      await tester.pumpAndSettle();

      expect(find.text('APP LOGS'), findsOneWidget);
    });
  });
}
