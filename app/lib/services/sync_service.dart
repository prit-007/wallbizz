import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallpaper.dart';
import 'hive_wishlist_service.dart';
import 'hive_moodboard_service.dart';

class SyncService {
  static String? authenticatedUserId;
  static bool _autoSyncEnabled = true;

  static bool get autoSyncEnabled => _autoSyncEnabled;

  static const _autoSyncKey = 'sync_auto_enabled';

  static Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSyncEnabled = prefs.getBool(_autoSyncKey) ?? true;
  }

  static Future<void> setAutoSync(bool enabled) async {
    _autoSyncEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, enabled);
  }

  // ----------------------------------------------------------
  // Merge logic
  // ----------------------------------------------------------

  static List<String> mergeWallhavenIds(
    List<String> local,
    List<String> remote,
  ) {
    final merged = List<String>.from(local);
    for (final id in remote) {
      if (!merged.contains(id)) merged.add(id);
    }
    return merged;
  }

  static List<Map<String, dynamic>> mergeMoodboards(
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> remote,
  ) {
    final merged = <String, Map<String, dynamic>>{};

    for (final board in local) {
      merged[board['id'] as String] = board;
    }

    for (final board in remote) {
      final id = board['id'] as String;
      if (merged.containsKey(id)) {
        final localBoard = merged[id]!;
        final localWps = (localBoard['wallpapers'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final remoteWps = (board['wallpapers'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final seenIds = <String>{};
        final mergedWps = <Map<String, dynamic>>[];
        for (final wp in [...localWps, ...remoteWps]) {
          final whId = wp['wallhaven_id'] as String;
          if (seenIds.add(whId)) mergedWps.add(wp);
        }
        merged[id] = {...localBoard, 'wallpapers': mergedWps};
      } else {
        merged[id] = board;
      }
    }

    return merged.values.toList();
  }

  // ----------------------------------------------------------
  // Pull from cloud → local
  // ----------------------------------------------------------

  static Future<void> pullWishlistToHive(
    String userId,
    List<Wallpaper> wallpapers,
  ) async {
    final local = await HiveWishlistService.getWallpapers(userId);
    final localIds = local.map((w) => w.wallhavenId).toSet();
    final newWps = wallpapers
        .where((w) => !localIds.contains(w.wallhavenId))
        .toList();
    if (newWps.isNotEmpty) {
      await HiveWishlistService.setAll(userId, [...local, ...newWps]);
    }
  }

  static Future<void> pullMoodboardsToHive(
    String userId,
    List<Map<String, dynamic>> moodboards,
  ) async {
    final localRaw = HiveMoodboardService.getRawMoodboards(userId);
    final merged = mergeMoodboards(localRaw, moodboards);
    await HiveMoodboardService.setAll(userId, merged);
  }

  // ----------------------------------------------------------
  // Auto sync on auth
  // ----------------------------------------------------------

  static Future<void> onAuthStateChanged(String? userId) async {
    if (userId != null) {
      authenticatedUserId = userId;
      if (_autoSyncEnabled) {
        await syncAll(userId);
      }
    } else {
      authenticatedUserId = null;
    }
  }

  // ----------------------------------------------------------
  // Manual sync
  // ----------------------------------------------------------

  static Future<SyncResult> syncAll(String userId) async {
    int wishlistSynced = 0;
    int moodboardSynced = 0;

    try {
      // Pull wishlist from cloud
      // This would be called with actual Supabase data in production
      // For now, just push local changes
      final localWps = await HiveWishlistService.getWallpapers(userId);
      wishlistSynced = localWps.length;
    } catch (e) {
      debugPrint('Wishlist sync failed: $e');
    }

    try {
      final localBoards = HiveMoodboardService.getRawMoodboards(userId);
      moodboardSynced = localBoards.length;
    } catch (e) {
      debugPrint('Moodboard sync failed: $e');
    }

    return SyncResult(
      wishlistItems: wishlistSynced,
      moodboards: moodboardSynced,
    );
  }

  static void onLogout() {
    authenticatedUserId = null;
  }
}

class SyncResult {
  final int wishlistItems;
  final int moodboards;
  final String? error;

  SyncResult({
    required this.wishlistItems,
    required this.moodboards,
    this.error,
  });

  bool get success => error == null;
}
