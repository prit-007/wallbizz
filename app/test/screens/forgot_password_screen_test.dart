import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallbizz/config/theme_config.dart';
import 'package:wallbizz/screens/forgot_password_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late Directory tempDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    if (!dotenv.isInitialized) {
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=https://test.supabase.co\nSUPABASE_ANON_KEY=test-anon-key',
      );
    }
    tempDir = Directory.systemTemp.createTempSync('forgot_pw_test_');
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

  Widget buildTestApp() {
    return const MaterialApp(home: ForgotPasswordScreen());
  }

  group('ForgotPasswordScreen', () {
    testWidgets('renders RESET PASSWORD title', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('RESET\nPASSWORD'), findsOneWidget);
    });

    testWidgets('renders email input field', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders email hint text', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Email Address'), findsOneWidget);
    });

    testWidgets('renders SEND RESET LINK button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('SEND RESET LINK'), findsOneWidget);
    });

    testWidgets('renders BACK TO SIGN IN button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('BACK TO SIGN IN'), findsOneWidget);
    });

    testWidgets('renders description text', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Enter your email address and we will send'),
        findsOneWidget,
      );
    });

    testWidgets('is a StatefulWidget', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final state = tester.state<State>(find.byType(ForgotPasswordScreen));
      expect(state, isNotNull);
    });

    testWidgets('email field accepts text input', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('renders with black background', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('renders send button as ElevatedButton', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
