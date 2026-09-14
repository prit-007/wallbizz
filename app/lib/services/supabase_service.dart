import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../core/logger/logger.dart';
import '../models/moodboard.dart';
import '../models/wallpaper.dart';
import 'api_cache.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  static final wishlistNotifier = ValueNotifier<int>(0);
  static final moodboardNotifier = ValueNotifier<int>(0);

  final String _baseUrl = SupabaseConfig.url;
  final String _anonKey = SupabaseConfig.anonKey;
  static const _timeout = Duration(seconds: 15);
  static final _client = http.Client();

  Map<String, String> get _headers => {
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Content-Type': 'application/json',
  };

  String? get _userToken =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  Map<String, String> get _authHeaders {
    final token = _userToken;
    return {
      'apikey': _anonKey,
      'Authorization': 'Bearer ${token ?? _anonKey}',
      'Content-Type': 'application/json',
    };
  }

  Future<http.Response> _get(Uri url, {Map<String, String>? headers}) =>
      _client.get(url, headers: headers ?? _headers).timeout(_timeout);

  Future<http.Response> _post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _client
      .post(url, headers: headers ?? _headers, body: body)
      .timeout(_timeout);

  Future<http.Response> _delete(Uri url, {Map<String, String>? headers}) =>
      _client.delete(url, headers: headers ?? _headers).timeout(_timeout);

  // ----------------------------------------------------------
  // Wallpapers
  // ----------------------------------------------------------

  Future<List<Wallpaper>> fetchWallpapers({
    String? category,
    int page = 0,
    int pageSize = 24,
  }) async {
    final cacheKey = 'wallpapers:${category ?? 'all'}:$page';
    final cached = ApiCache.get(cacheKey);
    if (cached != null) {
      logDebug('Wallpapers cache hit: $cacheKey', domain: LogDomain.sync);
      final List<dynamic> data = json.decode(cached);
      return data.map((map) => Wallpaper.fromMap(map)).toList();
    }

    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = 'select=*&order=created_at.desc';
    if (category != null && category.isNotEmpty) {
      query += '&source_query=eq.$category';
    }

    final url = Uri.parse('$_baseUrl/rest/v1/wallpapers?$query');
    logDebug(
      'Fetching wallpapers: $category page=$page',
      domain: LogDomain.sync,
    );
    final response = await _get(
      url,
      headers: {..._headers, 'Range': '$from-$to'},
    );

    if (response.statusCode == 200) {
      ApiCache.set(cacheKey, response.body, const Duration(minutes: 3));
      final List<dynamic> data = json.decode(response.body);
      logDebug(
        'Fetched ${data.length} wallpapers ($category page=$page)',
        domain: LogDomain.sync,
      );
      return data.map((map) => Wallpaper.fromMap(map)).toList();
    }

    logWarning(
      'Failed to fetch wallpapers: ${response.statusCode}',
      domain: LogDomain.sync,
    );
    return [];
  }

  // ----------------------------------------------------------
  // Wallpaper UUID resolver
  // ----------------------------------------------------------

  /// Resolves a wallhaven_id (or UUID) to the actual DB UUID.
  /// If the id is already a valid UUID, returns it directly.
  /// Otherwise looks up by wallhaven_id in the wallpapers table.
  Future<String?> _resolveWallpaperUuid(String wallpaperId) async {
    if (wallpaperId.contains('-') && wallpaperId.length == 36) {
      return wallpaperId;
    }
    final whId = wallpaperId.startsWith('wh-')
        ? wallpaperId.substring(3)
        : wallpaperId;
    final url = Uri.parse(
      '$_baseUrl/rest/v1/wallpapers?wallhaven_id=eq.$whId&select=id',
    );
    final response = await _get(url, headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data[0]['id'] as String?;
      }
    }
    return null;
  }

  // ----------------------------------------------------------
  // Wishlist
  // ----------------------------------------------------------

  Future<List<Wallpaper>> fetchWishlist(String userId) async {
    final cacheKey = 'wishlist:$userId';
    final cached = ApiCache.get(cacheKey);
    if (cached != null) {
      final List<dynamic> data = json.decode(cached);
      return data.map((item) => Wallpaper.fromMap(item['wallpapers'])).toList();
    }

    final url = Uri.parse(
      '$_baseUrl/rest/v1/wishlists?select=wallpapers(*),created_at&user_id=eq.$userId&order=created_at.desc',
    );
    final response = await _get(url, headers: _authHeaders);

    if (response.statusCode == 200) {
      ApiCache.set(cacheKey, response.body, const Duration(minutes: 2));
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Wallpaper.fromMap(item['wallpapers'])).toList();
    }

    return [];
  }

  Future<bool> addToWishlist(String userId, String wallpaperId) async {
    final uuid = await _resolveWallpaperUuid(wallpaperId);
    if (uuid == null) {
      logError(
        'addToWishlist: wallpaper not found in DB: $wallpaperId',
        domain: LogDomain.auth,
      );
      return false;
    }
    final url = Uri.parse('$_baseUrl/rest/v1/wishlists');
    logInfo(
      'Adding to wishlist: $wallpaperId -> $uuid',
      domain: LogDomain.auth,
    );
    final response = await _post(
      url,
      headers: _authHeaders,
      body: json.encode({'user_id': userId, 'wallpaper_id': uuid}),
    );

    final success = response.statusCode == 201 || response.statusCode == 200;
    if (success) {
      ApiCache.invalidatePrefix('wishlist:$userId');
      logInfo('Added to wishlist: $wallpaperId', domain: LogDomain.auth);
    } else {
      logError(
        'Failed to add to wishlist: ${response.statusCode} ${response.body}',
        domain: LogDomain.auth,
      );
    }
    return success;
  }

  Future<bool> removeFromWishlist(String userId, String wallpaperId) async {
    final uuid = await _resolveWallpaperUuid(wallpaperId);
    if (uuid == null) return false;
    final url = Uri.parse(
      '$_baseUrl/rest/v1/wishlists?wallpaper_id=eq.$uuid&user_id=eq.$userId',
    );
    logInfo('Removing from wishlist: $wallpaperId', domain: LogDomain.auth);
    final response = await _delete(url, headers: _authHeaders);

    final success = response.statusCode == 200 || response.statusCode == 204;
    if (success) {
      ApiCache.invalidatePrefix('wishlist:$userId');
      logInfo('Removed from wishlist: $wallpaperId', domain: LogDomain.auth);
    } else {
      logError(
        'Failed to remove from wishlist: ${response.statusCode}',
        domain: LogDomain.auth,
      );
    }
    return success;
  }

  Future<bool> isInWishlist(String userId, String wallpaperId) async {
    final uuid = await _resolveWallpaperUuid(wallpaperId);
    if (uuid == null) return false;
    final url = Uri.parse(
      '$_baseUrl/rest/v1/wishlists?wallpaper_id=eq.$uuid&user_id=eq.$userId&select=id',
    );
    final response = await _get(url, headers: _authHeaders);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.isNotEmpty;
    }

    return false;
  }

  // ----------------------------------------------------------
  // Moodboards
  // ----------------------------------------------------------

  Future<List<Moodboard>> fetchMoodboards(String userId) async {
    final cacheKey = 'moodboards:$userId';
    final cached = ApiCache.get(cacheKey);
    if (cached != null) {
      final List<dynamic> data = json.decode(cached);
      return data.map((map) => Moodboard.fromJson(map)).toList();
    }

    final url = Uri.parse(
      '$_baseUrl/rest/v1/moodboards?select=id,name,created_at,item_count:moodboard_items(count)&user_id=eq.$userId&order=created_at.desc',
    );
    final response = await _get(url, headers: _authHeaders);

    if (response.statusCode == 200) {
      ApiCache.set(cacheKey, response.body, const Duration(minutes: 2));
      final List<dynamic> data = json.decode(response.body);
      return data.map((map) => Moodboard.fromJson(map)).toList();
    }

    return [];
  }

  Future<Moodboard?> createMoodboard(String userId, String name) async {
    final url = Uri.parse('$_baseUrl/rest/v1/moodboards');
    logInfo('Creating moodboard: $name', domain: LogDomain.general);
    final response = await _post(
      url,
      headers: _authHeaders,
      body: json.encode({'user_id': userId, 'name': name}),
    );

    if (response.statusCode == 201) {
      moodboardNotifier.value++;
      ApiCache.invalidatePrefix('moodboards:$userId');
      logInfo('Created moodboard: $name', domain: LogDomain.general);
      return Moodboard.fromJson(json.decode(response.body));
    }

    logError(
      'Failed to create moodboard: ${response.statusCode}',
      domain: LogDomain.general,
    );
    return null;
  }

  Future<bool> deleteMoodboard(String moodboardId) async {
    final url = Uri.parse('$_baseUrl/rest/v1/moodboards?id=eq.$moodboardId');
    logInfo('Deleting moodboard: $moodboardId', domain: LogDomain.general);
    final response = await _delete(url, headers: _authHeaders);

    if (response.statusCode == 200 || response.statusCode == 204) {
      moodboardNotifier.value++;
      ApiCache.invalidatePrefix('moodboards:');
      logInfo('Deleted moodboard: $moodboardId', domain: LogDomain.general);
      return true;
    }

    logError(
      'Failed to delete moodboard: ${response.statusCode}',
      domain: LogDomain.general,
    );
    return false;
  }

  Future<bool> addToMoodboard(String moodboardId, String wallpaperId) async {
    final uuid = await _resolveWallpaperUuid(wallpaperId);
    if (uuid == null) {
      logError(
        'addToMoodboard: wallpaper not found in DB: $wallpaperId',
        domain: LogDomain.general,
      );
      return false;
    }
    final url = Uri.parse('$_baseUrl/rest/v1/moodboard_items');
    logInfo(
      'Adding to moodboard: $moodboardId <- $uuid',
      domain: LogDomain.general,
    );
    final response = await _post(
      url,
      headers: _authHeaders,
      body: json.encode({'moodboard_id': moodboardId, 'wallpaper_id': uuid}),
    );

    if (response.statusCode == 201) {
      moodboardNotifier.value++;
      ApiCache.invalidatePrefix('moodboard_items:$moodboardId');
      return true;
    }
    logError(
      'Failed to add to moodboard: ${response.statusCode}',
      domain: LogDomain.general,
    );
    return false;
  }

  Future<bool> removeFromMoodboard(
    String moodboardId,
    String wallpaperId,
  ) async {
    final uuid = await _resolveWallpaperUuid(wallpaperId);
    if (uuid == null) return false;
    final url = Uri.parse(
      '$_baseUrl/rest/v1/moodboard_items?moodboard_id=eq.$moodboardId&wallpaper_id=eq.$uuid',
    );
    logInfo(
      'Removing from moodboard: $moodboardId <- $wallpaperId',
      domain: LogDomain.general,
    );
    final response = await _delete(url, headers: _authHeaders);

    if (response.statusCode == 200 || response.statusCode == 204) {
      moodboardNotifier.value++;
      ApiCache.invalidatePrefix('moodboard_items:$moodboardId');
      return true;
    }
    logError(
      'Failed to remove from moodboard: ${response.statusCode}',
      domain: LogDomain.general,
    );
    return false;
  }

  Future<List<Wallpaper>> fetchMoodboardItems(String moodboardId) async {
    final cacheKey = 'moodboard_items:$moodboardId';
    final cached = ApiCache.get(cacheKey);
    if (cached != null) {
      final List<dynamic> data = json.decode(cached);
      return data.map((item) => Wallpaper.fromMap(item['wallpapers'])).toList();
    }

    final url = Uri.parse(
      '$_baseUrl/rest/v1/moodboard_items?select=wallpapers(*)&moodboard_id=eq.$moodboardId&order=added_at.desc',
    );
    final response = await _get(url, headers: _authHeaders);

    if (response.statusCode == 200) {
      ApiCache.set(cacheKey, response.body, const Duration(minutes: 2));
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Wallpaper.fromMap(item['wallpapers'])).toList();
    }

    return [];
  }

  Future<Set<String>> fetchMoodboardItemIds(String wallpaperId) async {
    final uuid = await _resolveWallpaperUuid(wallpaperId);
    if (uuid == null) return {};
    final url = Uri.parse(
      '$_baseUrl/rest/v1/moodboard_items?select=moodboard_id&wallpaper_id=eq.$uuid',
    );
    final response = await _get(url, headers: _authHeaders);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => item['moodboard_id'] as String).toSet();
    }

    return {};
  }
}
