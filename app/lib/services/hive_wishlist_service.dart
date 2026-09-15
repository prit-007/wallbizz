import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/wallpaper.dart';

class HiveWishlistService {
  static const String _boxName = 'wishlists';
  static Box get _box => Hive.box(_boxName);

  static final ValueNotifier<int> wishlistNotifier = ValueNotifier<int>(0);

  static Future<List<Wallpaper>> getWallpapers(String userId) async {
    final raw = _box.get(userId);
    if (raw == null) return [];
    return (raw as List)
        .map((e) => Wallpaper.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<List<String>> getWallhavenIds(String userId) async {
    final wps = await getWallpapers(userId);
    return wps.map((w) => w.wallhavenId).toList();
  }

  static Future<bool> isWishlisted(String userId, String wallhavenId) async {
    final ids = await getWallhavenIds(userId);
    return ids.contains(wallhavenId);
  }

  static Future<bool> add(String userId, Wallpaper wallpaper) async {
    final wps = await getWallpapers(userId);
    if (wps.any((w) => w.wallhavenId == wallpaper.wallhavenId)) return false;
    wps.add(wallpaper);
    await _box.put(userId, wps.map((w) => w.toMap()).toList());
    wishlistNotifier.value++;
    return true;
  }

  static Future<bool> remove(String userId, String wallhavenId) async {
    final wps = await getWallpapers(userId);
    final original = wps.length;
    wps.removeWhere((w) => w.wallhavenId == wallhavenId);
    if (wps.length == original) return false;
    await _box.put(userId, wps.map((w) => w.toMap()).toList());
    wishlistNotifier.value++;
    return true;
  }

  static Future<bool> toggle(String userId, Wallpaper wallpaper) async {
    final isCurrently = await isWishlisted(userId, wallpaper.wallhavenId);
    if (isCurrently) {
      await remove(userId, wallpaper.wallhavenId);
      return false;
    } else {
      await add(userId, wallpaper);
      return true;
    }
  }

  static Future<void> setAll(String userId, List<Wallpaper> wallpapers) async {
    await _box.put(userId, wallpapers.map((w) => w.toMap()).toList());
  }
}
