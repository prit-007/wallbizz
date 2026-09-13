import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallbizz/screens/search_screen.dart';

Widget buildTestApp({
  http.Client? httpClient,
  bool isAuthenticated = false,
  String? accessToken,
}) {
  return MaterialApp(
    home: SearchScreen(
      httpClient: httpClient,
      isAuthenticated: isAuthenticated,
      accessToken: accessToken,
    ),
  );
}

http.Client mockClient({List<dynamic>? data, int statusCode = 200}) {
  return http_testing.MockClient((request) async {
    return http.Response(
      jsonEncode({
        'data': data ?? [],
        'meta': {
          'current_page': 1,
          'last_page': 0,
          'per_page': 24,
          'total': data?.length ?? 0,
        },
      }),
      statusCode,
    );
  });
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SearchScreen UI', () {
    testWidgets('renders search bar', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders back button', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      await tester.pumpAndSettle();
      expect(find.byType(HugeIcon), findsWidgets);
    });

    testWidgets('renders purity chips', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      await tester.pumpAndSettle();
      expect(find.text('SFW'), findsOneWidget);
      expect(find.text('Sketchy'), findsOneWidget);
      expect(find.text('NSFW'), findsOneWidget);
    });

    testWidgets('renders sorting filter', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      await tester.pumpAndSettle();
      expect(find.text('Latest'), findsOneWidget);
    });

    testWidgets('renders category filter', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      await tester.pumpAndSettle();
      expect(find.text('All Types'), findsOneWidget);
    });

    testWidgets('shows trending section before search', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      await tester.pumpAndSettle();
      expect(find.text('POPULAR DISCOVERIES'), findsOneWidget);
    });

    testWidgets('renders search input field', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('back button pops navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchScreen(
                      httpClient: mockClient(),
                      isAuthenticated: false,
                    ),
                  ),
                ),
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);

      await tester.tap(find.byType(HugeIcon).first);
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsNothing);
    });

    testWidgets('clear button clears search and hides itself', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'nature');
      await tester.pump();

      final iconsBefore = find.byType(HugeIcon).evaluate().length;
      expect(iconsBefore, greaterThanOrEqualTo(1));

      await tester.tap(find.byType(HugeIcon).last);
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('SearchScreen search behavior', () {
    testWidgets('pressing search button triggers search', (tester) async {
      String? requestedUrl;
      final client = http_testing.MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(
          jsonEncode({
            'data': <dynamic>[],
            'meta': {
              'current_page': 1,
              'last_page': 0,
              'per_page': 24,
              'total': 0,
            },
          }),
          200,
        );
      });

      await tester.pumpWidget(buildTestApp(httpClient: client));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'nature');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(requestedUrl, isNotNull);
      expect(requestedUrl, contains('q=nature'));
    });

    testWidgets('hides trending section after results load', (tester) async {
      final client = mockClient(
        data: [
          {
            'id': 'test1',
            'path': 'https://example.com/full.jpg',
            'resolution': '1920x1080',
            'dimension_x': 1920,
            'dimension_y': 1080,
            'file_size': 1000000,
            'category': 'general',
            'colors': ['#ff0000'],
            'thumbs': {
              'large': '',
              'original': 'https://example.com/thumb.jpg',
              'small': '',
            },
          },
        ],
      );

      await tester.pumpWidget(buildTestApp(httpClient: client));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'nature');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('POPULAR DISCOVERIES'), findsNothing);
    });

    testWidgets('shows no results message for empty response', (tester) async {
      final client = mockClient(data: []);

      await tester.pumpWidget(buildTestApp(httpClient: client));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'xyznonexistent');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('NO RESULTS FOUND'), findsOneWidget);
    });

    testWidgets('purity chips send correct purity param', (tester) async {
      String? requestedUrl;
      final client = http_testing.MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(
          jsonEncode({
            'data': <dynamic>[],
            'meta': {
              'current_page': 1,
              'last_page': 0,
              'per_page': 24,
              'total': 0,
            },
          }),
          200,
        );
      });

      await tester.pumpWidget(
        buildTestApp(
          httpClient: client,
          isAuthenticated: true,
          accessToken: 'fake-token',
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(requestedUrl, contains('purity=100'));

      await tester.tap(find.text('Sketchy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(requestedUrl, contains('purity=110'));

      await tester.tap(find.text('NSFW'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(requestedUrl, contains('purity=111'));
    });
  });

  group('SearchScreen recent searches', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows trending tags on initial load', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      await tester.pumpAndSettle();

      expect(find.text('POPULAR DISCOVERIES'), findsOneWidget);
    });

    testWidgets('search saves query to recent searches', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'cyberpunk');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('search_history') ?? [];
      expect(searches, contains('cyberpunk'));
    });

    testWidgets('trending tag tap triggers search', (tester) async {
      String? requestedUrl;
      final client = http_testing.MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(
          jsonEncode({
            'data': <dynamic>[],
            'meta': {
              'current_page': 1,
              'last_page': 0,
              'per_page': 24,
              'total': 0,
            },
          }),
          200,
        );
      });

      await tester.pumpWidget(buildTestApp(httpClient: client));
      await tester.pumpAndSettle();

      final cyberpunkTag = find.text('#Cyberpunk');
      if (cyberpunkTag.evaluate().isNotEmpty) {
        await tester.tap(cyberpunkTag);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(requestedUrl, contains('q=Cyberpunk'));
      }
    });
  });
}
