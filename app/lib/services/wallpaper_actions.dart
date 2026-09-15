import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger/logger.dart';
import '../models/wallpaper.dart';
import '../services/hive_wishlist_service.dart';

class WallpaperActions {
  static Wallpaper? _pendingWallpaper;
  static bool _isProcessing = false;

  static void handleHeartTap(
    BuildContext context,
    Wallpaper wallpaper, {
    VoidCallback? onToggle,
    VoidCallback? onComplete,
  }) {
    if (_isProcessing) return;

    onToggle?.call();
    _toggleLocal(context, wallpaper, onComplete);
  }

  static Future<void> _toggleLocal(
    BuildContext context,
    Wallpaper wallpaper,
    VoidCallback? onComplete,
  ) async {
    _isProcessing = true;
    try {
      final userId = _localUserId;
      logInfo(
        'Toggling wishlist locally: ${wallpaper.wallhavenId}',
        domain: LogDomain.auth,
      );
      final added = await HiveWishlistService.toggle(userId, wallpaper);

      logInfo(
        'Wishlist toggle: ${added ? "added" : "removed"} ${wallpaper.wallhavenId}',
        domain: LogDomain.auth,
      );
      onComplete?.call();

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _syncToCloud(user.id, wallpaper.wallhavenId, added);
      }
    } catch (e, st) {
      logError(
        'Wishlist toggle failed: ${wallpaper.wallhavenId}',
        error: e,
        stackTrace: st,
        domain: LogDomain.auth,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Something went wrong. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  static String get _localUserId {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id ?? 'anonymous';
  }

  static Future<void> _syncToCloud(
    String userId,
    String wallhavenId,
    bool added,
  ) async {
    try {
      if (added) {
        await Supabase.instance.client.from('wishlists_v2').insert({
          'user_id': userId,
          'wallhaven_id': wallhavenId,
        });
      } else {
        await Supabase.instance.client
            .from('wishlists_v2')
            .delete()
            .eq('user_id', userId)
            .eq('wallhaven_id', wallhavenId);
      }
    } catch (e) {
      logWarning(
        'Cloud sync failed for wishlist: $wallhavenId',
        domain: LogDomain.auth,
      );
    }
  }

  static void onAuthSuccess() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _pendingWallpaper != null) {
      final wp = _pendingWallpaper!;
      _pendingWallpaper = null;
      _isProcessing = true;
      HiveWishlistService.toggle(user.id, wp)
          .then((_) {
            _isProcessing = false;
          })
          .catchError((_) {
            _isProcessing = false;
          });
    }
  }
}
