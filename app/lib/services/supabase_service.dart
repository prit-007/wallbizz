import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/moodboard.dart';
import '../models/wallpaper.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  static final wishlistNotifier = ValueNotifier<int>(0);
  static final moodboardNotifier = ValueNotifier<int>(0);

  final String _baseUrl = SupabaseConfig.url;
  final String _anonKey = SupabaseConfig.anonKey;

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

  // ----------------------------------------------------------
  // Wallpapers
  // ----------------------------------------------------------

  Future<List<Wallpaper>> fetchWallpapers({
    String? category,
    int page = 0,
    int pageSize = 24,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = 'select=*&order=created_at.desc';
    if (category != null && category.isNotEmpty) {
      query += '&source_query=eq.$category';
    }

    final url = Uri.parse('$_baseUrl/rest/v1/wallpapers?$query');
    final response = await http.get(
      url,
      headers: {
        ..._headers,
        'Range': '$from-$to',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((map) => Wallpaper.fromMap(map)).toList();
    }

    return [];
  }

  // ----------------------------------------------------------
  // Wishlist
  // ----------------------------------------------------------

  Future<List<Wallpaper>> fetchWishlist(String userId) async {
    final url = Uri.parse(
      '$_baseUrl/rest/v1/wishlists?select=wallpapers(*),created_at&order=created_at.desc',
    );
    final response = await http.get(url, headers: _authHeaders);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((item) => Wallpaper.fromMap(item['wallpapers']))
          .toList();
    }

    return [];
  }

  Future<bool> addToWishlist(String userId, String wallpaperId) async {
    final url = Uri.parse('$_baseUrl/rest/v1/wishlists');
    final response = await http.post(
      url,
      headers: _authHeaders,
      body: json.encode({
        'user_id': userId,
        'wallpaper_id': wallpaperId,
      }),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<bool> removeFromWishlist(String userId, String wallpaperId) async {
    final url = Uri.parse(
      '$_baseUrl/rest/v1/wishlists?wallpaper_id=eq.$wallpaperId',
    );
    final response = await http.delete(url, headers: _authHeaders);

    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<bool> isInWishlist(String userId, String wallpaperId) async {
    final url = Uri.parse(
      '$_baseUrl/rest/v1/wishlists?wallpaper_id=eq.$wallpaperId&select=id',
    );
    final response = await http.get(url, headers: _authHeaders);

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
    final url = Uri.parse(
      '$_baseUrl/rest/v1/moodboards?select=id,name,created_at,item_count:moodboard_items(count)&user_id=eq.$userId&order=created_at.desc',
    );
    final response = await http.get(url, headers: _authHeaders);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((map) => Moodboard.fromJson(map)).toList();
    }

    return [];
  }

  Future<Moodboard?> createMoodboard(String userId, String name) async {
    final url = Uri.parse('$_baseUrl/rest/v1/moodboards');
    final response = await http.post(
      url,
      headers: _authHeaders,
      body: json.encode({
        'user_id': userId,
        'name': name,
      }),
    );

    if (response.statusCode == 201) {
      moodboardNotifier.value++;
      return Moodboard.fromJson(json.decode(response.body));
    }

    return null;
  }

  Future<bool> deleteMoodboard(String moodboardId) async {
    final url = Uri.parse(
      '$_baseUrl/rest/v1/moodboards?id=eq.$moodboardId',
    );
    final response = await http.delete(url, headers: _authHeaders);

    if (response.statusCode == 200 || response.statusCode == 204) {
      moodboardNotifier.value++;
      return true;
    }

    return false;
  }

  Future<bool> addToMoodboard(String moodboardId, String wallpaperId) async {
    final url = Uri.parse('$_baseUrl/rest/v1/moodboard_items');
    final response = await http.post(
      url,
      headers: _authHeaders,
      body: json.encode({
        'moodboard_id': moodboardId,
        'wallpaper_id': wallpaperId,
      }),
    );

    if (response.statusCode == 201) {
      moodboardNotifier.value++;
      return true;
    }
    return false;
  }

  Future<bool> removeFromMoodboard(String moodboardId, String wallpaperId) async {
    final url = Uri.parse(
      '$_baseUrl/rest/v1/moodboard_items?moodboard_id=eq.$moodboardId&wallpaper_id=eq.$wallpaperId',
    );
    final response = await http.delete(url, headers: _authHeaders);

    if (response.statusCode == 200 || response.statusCode == 204) {
      moodboardNotifier.value++;
      return true;
    }
    return false;
  }

  Future<List<Wallpaper>> fetchMoodboardItems(String moodboardId) async {
    final url = Uri.parse(
      '$_baseUrl/rest/v1/moodboard_items?select=wallpapers(*)&moodboard_id=eq.$moodboardId&order=added_at.desc',
    );
    final response = await http.get(url, headers: _authHeaders);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Wallpaper.fromMap(item['wallpapers'])).toList();
    }

    return [];
  }

  Future<Set<String>> fetchMoodboardItemIds(String wallpaperId) async {
    final url = Uri.parse(
      '$_baseUrl/rest/v1/moodboard_items?select=moodboard_id&wallpaper_id=eq.$wallpaperId',
    );
    final response = await http.get(url, headers: _authHeaders);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => item['moodboard_id'] as String).toSet();
    }

    return {};
  }
}
