import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:wallbizz/services/wallhaven_search.dart';
import 'package:wallbizz/services/api_cache.dart';

void main() {
  setUp(() {
    ApiCache.clear();
  });
  group('SearchResult', () {
    test('holds wallpapers and meta', () {
      final result = SearchResult(
        wallpapers: [],
        currentPage: 1,
        lastPage: 5,
        total: 120,
      );
      expect(result.wallpapers, isEmpty);
      expect(result.currentPage, 1);
      expect(result.lastPage, 5);
      expect(result.total, 120);
    });

    test('hasMore returns true when not on last page', () {
      final result = SearchResult(
        wallpapers: [],
        currentPage: 1,
        lastPage: 5,
        total: 120,
      );
      expect(result.hasMore, true);
    });

    test('hasMore returns false when on last page', () {
      final result = SearchResult(
        wallpapers: [],
        currentPage: 5,
        lastPage: 5,
        total: 120,
      );
      expect(result.hasMore, false);
    });

    test('hasMore returns false when lastPage is 0', () {
      final result = SearchResult(
        wallpapers: [],
        currentPage: 1,
        lastPage: 0,
        total: 0,
      );
      expect(result.hasMore, false);
    });
  });

  group('WallhavenSearch URL building', () {
    test('builds public search URL with query', () {
      final url = WallhavenSearch.buildPublicURL(
        query: 'nature',
        page: 1,
        purity: '100',
        sorting: 'toplist',
        topRange: '3M',
      );
      expect(url, contains('wallhaven.cc/api/v1/search'));
      expect(url, contains('q=nature'));
      expect(url, contains('purity=100'));
      expect(url, contains('sorting=toplist'));
      expect(url, contains('topRange=3M'));
      expect(url, contains('page=1'));
      expect(url, isNot(contains('apikey')));
    });

    test('builds public URL with ratios', () {
      final url = WallhavenSearch.buildPublicURL(
        query: 'desktop',
        page: 1,
        purity: '100',
        sorting: 'toplist',
        topRange: '3M',
        ratios: '16x9',
      );
      expect(url, contains('ratios=16x9'));
    });

    test('builds public URL with categories', () {
      final url = WallhavenSearch.buildPublicURL(
        query: 'anime',
        page: 1,
        purity: '100',
        sorting: 'toplist',
        topRange: '3M',
        categories: '010',
      );
      expect(url, contains('categories=010'));
    });

    test('builds authenticated search URL with backend base', () {
      final url = WallhavenSearch.buildAuthenticatedURL(
        backendBase: 'https://wallbizz.onrender.com',
        query: 'nature',
        page: 2,
        purity: '111',
        sorting: 'relevance',
        topRange: '1M',
      );
      expect(url, contains('wallbizz.onrender.com/api/v1/search'));
      expect(url, contains('q=nature'));
      expect(url, contains('purity=111'));
      expect(url, contains('sorting=relevance'));
      expect(url, contains('topRange=1M'));
      expect(url, contains('page=2'));
    });

    test('builds URL with all filter params', () {
      final url = WallhavenSearch.buildPublicURL(
        query: 'dark forest',
        page: 3,
        purity: '100',
        sorting: 'favorites',
        topRange: '6M',
        ratios: '16x9,16x10',
        categories: '111',
        colors: '000000',
      );
      expect(url, contains('q=dark%20forest'));
      expect(url, contains('ratios=16x9,16x10'));
      expect(url, contains('categories=111'));
      expect(url, contains('colors=000000'));
    });

    test('handles empty query', () {
      final url = WallhavenSearch.buildPublicURL(
        query: '',
        page: 1,
        purity: '100',
        sorting: 'toplist',
        topRange: '3M',
      );
      expect(url, isNot(contains('q=')));
    });
  });

  group('WallhavenSearch.parseResponse', () {
    test('parses valid Wallhaven response', () {
      final json = {
        'data': [
          {
            'id': 'abc123',
            'path': 'https://w.wallhaven.cc/full/ab/abc123.jpg',
            'resolution': '1920x1080',
            'dimension_x': 1920,
            'dimension_y': 1080,
            'file_size': 1000000,
            'category': 'general',
            'colors': ['#111111'],
            'thumbs': {
              'large': 'https://th.wallhaven.cc/lg/ab/abc123.jpg',
              'original': 'https://th.wallhaven.cc/orig/ab/abc123.jpg',
              'small': 'https://th.wallhaven.cc/sm/ab/abc123.jpg',
            },
          },
        ],
        'meta': {
          'current_page': 1,
          'last_page': 5,
          'per_page': 24,
          'total': 120,
        },
      };

      final result = WallhavenSearch.parseResponse(json);
      expect(result.wallpapers.length, 1);
      expect(result.wallpapers[0].wallhavenId, 'abc123');
      expect(
        result.wallpapers[0].urlFull,
        'https://w.wallhaven.cc/full/ab/abc123.jpg',
      );
      expect(
        result.wallpapers[0].urlThumb,
        'https://th.wallhaven.cc/sm/ab/abc123.jpg',
      );
      expect(result.currentPage, 1);
      expect(result.lastPage, 5);
      expect(result.total, 120);
    });

    test('parses empty data array', () {
      final json = {
        'data': <dynamic>[],
        'meta': {'current_page': 1, 'last_page': 0, 'per_page': 24, 'total': 0},
      };

      final result = WallhavenSearch.parseResponse(json);
      expect(result.wallpapers, isEmpty);
      expect(result.total, 0);
    });

    test('handles missing meta fields', () {
      final json = {'data': <dynamic>[], 'meta': <String, dynamic>{}};

      final result = WallhavenSearch.parseResponse(json);
      expect(result.currentPage, 0);
      expect(result.lastPage, 0);
      expect(result.total, 0);
    });

    test('handles completely empty response', () {
      final result = WallhavenSearch.parseResponse({});
      expect(result.wallpapers, isEmpty);
      expect(result.currentPage, 0);
      expect(result.lastPage, 0);
    });
  });

  group('WallhavenSearch.searchPublic', () {
    test('makes correct GET request to Wallhaven', () async {
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

      final search = WallhavenSearch(httpClient: client);
      await search.searchPublic(query: 'nature', page: 1);

      expect(requestedUrl, contains('wallhaven.cc/api/v1/search'));
      expect(requestedUrl, contains('q=nature'));
      expect(requestedUrl, contains('purity=100'));
    });

    test('returns parsed wallpapers', () async {
      final client = http_testing.MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'xyz789',
                'path': 'https://w.wallhaven.cc/full/xy/xyz789.jpg',
                'resolution': '2560x1440',
                'dimension_x': 2560,
                'dimension_y': 1440,
                'file_size': 2000000,
                'category': 'anime',
                'colors': ['#ff0000'],
                'thumbs': {
                  'large': '',
                  'original': 'https://th.wallhaven.cc/orig/xy/xyz789.jpg',
                  'small': '',
                },
              },
            ],
            'meta': {
              'current_page': 1,
              'last_page': 3,
              'per_page': 24,
              'total': 72,
            },
          }),
          200,
        );
      });

      final search = WallhavenSearch(httpClient: client);
      final result = await search.searchPublic(query: 'anime', page: 1);

      expect(result.wallpapers.length, 1);
      expect(result.wallpapers[0].wallhavenId, 'xyz789');
      expect(result.lastPage, 3);
      expect(result.total, 72);
    });

    test('returns empty result on error', () async {
      final client = http_testing.MockClient((request) async {
        return http.Response('error', 500);
      });

      final search = WallhavenSearch(httpClient: client);
      final result = await search.searchPublic(query: 'test', page: 1);

      expect(result.wallpapers, isEmpty);
      expect(result.total, 0);
    });

    test('returns empty result on network error', () async {
      final client = http_testing.MockClient((request) async {
        throw Exception('network error');
      });

      final search = WallhavenSearch(httpClient: client);
      final result = await search.searchPublic(query: 'test', page: 1);

      expect(result.wallpapers, isEmpty);
    });

    test('sends correct filter params', () async {
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

      final search = WallhavenSearch(httpClient: client);
      await search.searchPublic(
        query: 'dark',
        page: 2,
        purity: '110',
        sorting: 'favorites',
        topRange: '1y',
        ratios: '16x9',
        categories: '010',
        colors: '000000',
      );

      expect(requestedUrl, contains('q=dark'));
      expect(requestedUrl, contains('page=2'));
      expect(requestedUrl, contains('purity=110'));
      expect(requestedUrl, contains('sorting=favorites'));
      expect(requestedUrl, contains('topRange=1y'));
      expect(requestedUrl, contains('ratios=16x9'));
      expect(requestedUrl, contains('categories=010'));
      expect(requestedUrl, contains('colors=000000'));
    });
  });

  group('WallhavenSearch.searchAuthenticated', () {
    test('sends Authorization header with token', () async {
      String? authHeader;

      final client = http_testing.MockClient((request) async {
        authHeader = request.headers['Authorization'];
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

      final search = WallhavenSearch(httpClient: client);
      await search.searchAuthenticated(
        query: 'nsfw',
        page: 1,
        token: 'my-jwt-token',
        backendBase: 'https://wallbizz.onrender.com',
      );

      expect(authHeader, 'Bearer my-jwt-token');
    });

    test('calls backend proxy instead of Wallhaven directly', () async {
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

      final search = WallhavenSearch(httpClient: client);
      await search.searchAuthenticated(
        query: 'nsfw',
        page: 1,
        token: 'token',
        backendBase: 'https://wallbizz.onrender.com',
      );

      expect(requestedUrl, contains('wallbizz.onrender.com/api/v1/search'));
      expect(requestedUrl, isNot(contains('wallhaven.cc')));
    });

    test('forwards purity 111 for NSFW', () async {
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

      final search = WallhavenSearch(httpClient: client);
      await search.searchAuthenticated(
        query: 'test',
        page: 1,
        token: 'token',
        backendBase: 'https://backend.example.com',
        purity: '111',
      );

      expect(requestedUrl, contains('purity=111'));
    });

    test('returns empty result on 401', () async {
      final client = http_testing.MockClient((request) async {
        return http.Response('{"error":"invalid token"}', 401);
      });

      final search = WallhavenSearch(httpClient: client);
      final result = await search.searchAuthenticated(
        query: 'test',
        page: 1,
        token: 'bad-token',
        backendBase: 'https://backend.example.com',
      );

      expect(result.wallpapers, isEmpty);
    });
  });
}
