import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/wallpaper.dart';

class SearchResult {
  final List<Wallpaper> wallpapers;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? error;

  SearchResult({
    required this.wallpapers,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.error,
  });

  bool get hasMore => currentPage < lastPage;
  bool get hasError => error != null;
}

class WallhavenSearch {
  static const _baseUrl = 'https://wallhaven.cc/api/v1/search';

  final http.Client _httpClient;

  WallhavenSearch({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static String buildPublicURL({
    required String query,
    required int page,
    required String purity,
    required String sorting,
    required String topRange,
    String? ratios,
    String? categories,
    String? colors,
  }) {
    final params = <String>[
      if (query.isNotEmpty) 'q=${Uri.encodeComponent(query)}',
      'page=$page',
      'purity=$purity',
      'sorting=$sorting',
      if (topRange.isNotEmpty) 'topRange=$topRange',
      if (ratios != null && ratios.isNotEmpty) 'ratios=$ratios',
      if (categories != null && categories.isNotEmpty) 'categories=$categories',
      if (colors != null && colors.isNotEmpty) 'colors=$colors',
    ];
    return '$_baseUrl?${params.join('&')}';
  }

  static String buildAuthenticatedURL({
    required String backendBase,
    required String query,
    required int page,
    required String purity,
    required String sorting,
    required String topRange,
    String? ratios,
    String? categories,
    String? colors,
  }) {
    final params = <String>[
      if (query.isNotEmpty) 'q=${Uri.encodeComponent(query)}',
      'page=$page',
      'purity=$purity',
      'sorting=$sorting',
      if (topRange.isNotEmpty) 'topRange=$topRange',
      if (ratios != null && ratios.isNotEmpty) 'ratios=$ratios',
      if (categories != null && categories.isNotEmpty) 'categories=$categories',
      if (colors != null && colors.isNotEmpty) 'colors=$colors',
    ];
    return '$backendBase/api/v1/search?${params.join('&')}';
  }

  static SearchResult parseResponse(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};

    final wallpapers = data
        .map((item) => Wallpaper.fromWallhavenMap(item as Map<String, dynamic>))
        .toList();

    return SearchResult(
      wallpapers: wallpapers,
      currentPage: meta['current_page'] ?? 0,
      lastPage: meta['last_page'] ?? 0,
      total: meta['total'] ?? 0,
    );
  }

  Future<SearchResult> searchPublic({
    required String query,
    required int page,
    String purity = '100',
    String sorting = 'date_added',
    String topRange = '',
    String? ratios,
    String? categories,
    String? colors,
    String? backendBase,
  }) async {
    String url;
    if (kIsWeb && backendBase != null && backendBase.isNotEmpty) {
      url = buildAuthenticatedURL(
        backendBase: backendBase,
        query: query,
        page: page,
        purity: purity,
        sorting: sorting,
        topRange: topRange,
        ratios: ratios,
        categories: categories,
        colors: colors,
      );
    } else {
      url = buildPublicURL(
        query: query,
        page: page,
        purity: purity,
        sorting: sorting,
        topRange: topRange,
        ratios: ratios,
        categories: categories,
        colors: colors,
      );
    }

    try {
      final response = await _httpClient.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return parseResponse(json);
      }
      final body = response.body;
      final msg = body.isNotEmpty ? body : 'HTTP ${response.statusCode}';
      return SearchResult(wallpapers: [], currentPage: 0, lastPage: 0, total: 0, error: msg);
    } catch (e) {
      return SearchResult(wallpapers: [], currentPage: 0, lastPage: 0, total: 0, error: e.toString());
    }
  }

  Future<SearchResult> searchAuthenticated({
    required String query,
    required int page,
    required String token,
    required String backendBase,
    String purity = '111',
    String sorting = 'date_added',
    String topRange = '',
    String? ratios,
    String? categories,
    String? colors,
  }) async {
    final url = buildAuthenticatedURL(
      backendBase: backendBase,
      query: query,
      page: page,
      purity: purity,
      sorting: sorting,
      topRange: topRange,
      ratios: ratios,
      categories: categories,
      colors: colors,
    );

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return parseResponse(json);
      }
      final body = response.body;
      final msg = body.isNotEmpty ? body : 'HTTP ${response.statusCode}';
      return SearchResult(wallpapers: [], currentPage: 0, lastPage: 0, total: 0, error: msg);
    } catch (e) {
      return SearchResult(wallpapers: [], currentPage: 0, lastPage: 0, total: 0, error: e.toString());
    }
  }
}
