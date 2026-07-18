import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:vivek_app/screens/search_screen.dart';

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
  group('SearchScreen UI', () {
    testWidgets('renders search bar', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders back button', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('renders purity chips', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      expect(find.text('SFW'), findsOneWidget);
      expect(find.text('Sketchy'), findsOneWidget);
      expect(find.text('NSFW'), findsOneWidget);
    });

    testWidgets('SFW chip selected by default', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      final sfwChip = tester.widget<ChoiceChip>(
          find.byKey(const Key('purity_sfw')));
      expect(sfwChip.selected, true);
    });

    testWidgets('renders sorting dropdown', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      expect(find.text('Toplist'), findsOneWidget);
    });

    testWidgets('renders category dropdown', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      expect(find.text('All'), findsWidgets);
    });

    testWidgets('shows empty state text before search', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      expect(find.text('Search millions of wallpapers'), findsOneWidget);
    });

    testWidgets('renders search input field', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('back button pops navigation', (tester) async {
      await tester.pumpWidget(MaterialApp(
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
      ));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsNothing);
    });

    testWidgets('clear button clears search and hides itself', (tester) async {
      await tester.pumpWidget(buildTestApp(httpClient: mockClient()));
      await tester.enterText(find.byType(TextField), 'nature');
      await tester.pump();

      final clearBtn = find.byKey(const Key('clear_button'));
      expect(clearBtn, findsOneWidget);

      await tester.tap(clearBtn);
      await tester.pump();

      expect(find.byKey(const Key('clear_button')), findsNothing);
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
      await tester.enterText(find.byType(TextField), 'nature');
      await tester.pump();

      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(requestedUrl, isNotNull);
      expect(requestedUrl, contains('q=nature'));
    });

    testWidgets('shows results in grid after search', (tester) async {
      final client = mockClient(data: [
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
      ]);

      await tester.pumpWidget(buildTestApp(httpClient: client));
      await tester.enterText(find.byType(TextField), 'nature');
      await tester.pump();

      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('1920x1080'), findsOneWidget);
    });

    testWidgets('hides empty state after results load', (tester) async {
      final client = mockClient(data: [
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
      ]);

      await tester.pumpWidget(buildTestApp(httpClient: client));
      await tester.enterText(find.byType(TextField), 'nature');
      await tester.pump();

      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Search millions of wallpapers'), findsNothing);
    });

    testWidgets('shows no results message for empty response',
        (tester) async {
      final client = mockClient(data: []);

      await tester.pumpWidget(buildTestApp(httpClient: client));
      await tester.enterText(find.byType(TextField), 'xyznonexistent');
      await tester.pump();

      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('No wallpapers found'), findsOneWidget);
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

      await tester.pumpWidget(buildTestApp(
        httpClient: client,
        isAuthenticated: true,
        accessToken: 'fake-token',
      ));

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(requestedUrl, contains('purity=100'));

      await tester.tap(find.byKey(const Key('purity_sketchy')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(requestedUrl, contains('purity=110'));

      await tester.tap(find.byKey(const Key('purity_nsfw')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(requestedUrl, contains('purity=111'));
    });
  });
}
