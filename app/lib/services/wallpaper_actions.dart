import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallpaper.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_bottom_sheet.dart';

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

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _pendingWallpaper = wallpaper;
      showAuthBottomSheet(
        context,
        onDismissed: () {
          _pendingWallpaper = null;
        },
      );
      return;
    }

    onToggle?.call();
    _toggleWishlist(context, user.id, wallpaper, onComplete);
  }

  static Future<void> _toggleWishlist(
    BuildContext context,
    String userId,
    Wallpaper wallpaper,
    VoidCallback? onComplete,
  ) async {
    _isProcessing = true;
    try {
      final isInList = await SupabaseService.instance.isInWishlist(
        userId,
        wallpaper.id,
      );

      bool success;
      if (isInList) {
        success = await SupabaseService.instance.removeFromWishlist(
          userId,
          wallpaper.id,
        );
      } else {
        success = await SupabaseService.instance.addToWishlist(
          userId,
          wallpaper.id,
        );
      }

      if (success) {
        onComplete?.call();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isInList
                  ? 'Failed to remove from collection'
                  : 'Failed to add to collection',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
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

  static void onAuthSuccess() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _pendingWallpaper != null) {
      final wp = _pendingWallpaper!;
      _pendingWallpaper = null;
      _isProcessing = true;
      SupabaseService.instance
          .addToWishlist(user.id, wp.id)
          .then((_) {
            _isProcessing = false;
          })
          .catchError((_) {
            _isProcessing = false;
          });
    }
  }
}
