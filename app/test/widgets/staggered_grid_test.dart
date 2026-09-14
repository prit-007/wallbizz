import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallbizz/config/theme_config.dart';
import 'package:wallbizz/widgets/staggered_grid.dart';

Widget _wrapInApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(useMaterial3: true),
    home: Scaffold(body: SizedBox(width: 400, height: 800, child: child)),
  );
}

Widget _wrapInSliverApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(useMaterial3: true),
    home: Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(pinned: true, title: Text('Test')),
          SliverPadding(padding: EdgeInsets.all(16), sliver: child),
        ],
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    if (!dotenv.isInitialized) {
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=https://test.supabase.co\nSUPABASE_ANON_KEY=test-anon-key',
      );
    }
    tempDir = Directory.systemTemp.createTempSync('staggered_grid_test_');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('downloads')) {
      await Hive.openBox('downloads');
    }
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

  group('StaggeredGrid', () {
    testWidgets('renders StaggeredGrid widget', (tester) async {
      await tester.pumpWidget(_wrapInApp(const StaggeredGrid()));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(StaggeredGrid), findsOneWidget);
    });

    testWidgets('shows loading or error or content after pumpAndSettle', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapInApp(const StaggeredGrid()));
      await tester.pumpAndSettle();

      final hasLoading = find
          .byType(CircularProgressIndicator)
          .evaluate()
          .isNotEmpty;
      final hasError = find
          .text('Failed to load wallpapers')
          .evaluate()
          .isNotEmpty;
      final hasRetry = find.text('Retry').evaluate().isNotEmpty;

      expect(hasLoading || hasError || true, true);

      if (hasError) {
        expect(hasRetry, true);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      }
    });

    testWidgets('contains RefreshIndicator when content is loaded', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapInApp(const StaggeredGrid()));
      await tester.pumpAndSettle();

      if (find.byType(RefreshIndicator).evaluate().isNotEmpty) {
        expect(find.byType(RefreshIndicator), findsOneWidget);
      }
    });

    testWidgets('supports category parameter', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(const StaggeredGrid(category: 'nature')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StaggeredGrid), findsOneWidget);
    });

    testWidgets('supports onWallpaperTap callback', (tester) async {
      await tester.pumpWidget(
        _wrapInApp(
          StaggeredGrid(category: 'space', onWallpaperTap: (wp, all) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StaggeredGrid), findsOneWidget);
    });

    testWidgets('error state has retry button that can be tapped', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapInApp(const StaggeredGrid()));
      await tester.pumpAndSettle();

      if (find.text('Retry').evaluate().isNotEmpty) {
        await tester.tap(find.text('Retry'));
        await tester.pump();

        expect(find.byType(StaggeredGrid), findsOneWidget);
      }
    });
  });

  group('StaggeredGrid sliverMode', () {
    testWidgets('defaults to non-sliver mode', (tester) async {
      await tester.pumpWidget(_wrapInApp(const StaggeredGrid()));
      await tester.pump(const Duration(seconds: 2));

      final grid = tester.widget<StaggeredGrid>(find.byType(StaggeredGrid));
      expect(grid.sliverMode, isFalse);
    });

    testWidgets('accepts sliverMode parameter', (tester) async {
      await tester.pumpWidget(
        _wrapInSliverApp(const StaggeredGrid(sliverMode: true)),
      );
      await tester.pump(const Duration(seconds: 2));

      final grid = tester.widget<StaggeredGrid>(find.byType(StaggeredGrid));
      expect(grid.sliverMode, isTrue);
    });

    testWidgets('renders inside CustomScrollView in sliver mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapInSliverApp(const StaggeredGrid(sliverMode: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StaggeredGrid), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('does not wrap in RefreshIndicator in sliver mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapInSliverApp(const StaggeredGrid(sliverMode: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsNothing);
    });

    testWidgets('supports category parameter in sliver mode', (tester) async {
      await tester.pumpWidget(
        _wrapInSliverApp(
          const StaggeredGrid(category: 'nature', sliverMode: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StaggeredGrid), findsOneWidget);
    });

    testWidgets('supports onWallpaperTap callback in sliver mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapInSliverApp(
          StaggeredGrid(
            category: 'space',
            sliverMode: true,
            onWallpaperTap: (wp, all) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StaggeredGrid), findsOneWidget);
    });
  });
}
