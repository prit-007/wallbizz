import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../models/wallpaper.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  final String _baseUrl = SupabaseConfig.url;
  final String _anonKey = SupabaseConfig.anonKey;

  Map<String, String> get _headers => {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
      };

  /// Fetch wallpapers, optionally filtered by source_query (category).
  /// [page] is 0-indexed. Returns up to [pageSize] results.
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

  /// Fetch wallpapers for a user's wishlist.
  Future<List<Wallpaper>> fetchWishlist(String userId) async {
    final url = Uri.parse(
      '$_baseUrl/rest/v1/wishlists?user_id=eq.$userId&select=wallpapers(*),created_at&order=created_at.desc',
    );
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((item) => Wallpaper.fromMap(item['wallpapers']))
          .toList();
    }

    return [];
  }

  /// Add a wallpaper to a user's wishlist.
  Future<bool> addToWishlist(String userId, String wallpaperId) async {
    final url = Uri.parse('$_baseUrl/rest/v1/wishlists');
    final response = await http.post(
      url,
      headers: _headers,
      body: json.encode({
        'user_id': userId,
        'wallpaper_id': wallpaperId,
      }),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  /// Remove a wallpaper from a user's wishlist.
  Future<bool> removeFromWishlist(String userId, String wallpaperId) async {
    final url = Uri.parse(
      '$_baseUrl/rest/v1/wishlists?user_id=eq.$userId&wallpaper_id=eq.$wallpaperId',
    );
    final response = await http.delete(url, headers: _headers);

    return response.statusCode == 200 || response.statusCode == 204;
  }

  /// Check if a wallpaper is in a user's wishlist.
  Future<bool> isInWishlist(String userId, String wallpaperId) async {
    final url = Uri.parse(
      '$_baseUrl/rest/v1/wishlists?user_id=eq.$userId&wallpaper_id=eq.$wallpaperId&select=id',
    );
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.isNotEmpty;
    }

    return false;
  }
}
