import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallpaper.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_bottom_sheet.dart';

class WallpaperActions {
  static Wallpaper? _pendingWallpaper;
  static VoidCallback? _onPendingComplete;

  /// Handle heart tap on a wallpaper card.
  /// Shows auth bottom sheet if user is not logged in.
  static void handleHeartTap(
    BuildContext context,
    Wallpaper wallpaper, {
    VoidCallback? onComplete,
  }) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _pendingWallpaper = wallpaper;
      _onPendingComplete = onComplete;
      showAuthBottomSheet(context);
      return;
    }

    _toggleWishlist(user.id, wallpaper, onComplete);
  }

  /// Toggle a wallpaper in the user's wishlist.
  static Future<void> _toggleWishlist(
    String userId,
    Wallpaper wallpaper,
    VoidCallback? onComplete,
  ) async {
    final isInList = await SupabaseService.instance.isInWishlist(
      userId,
      wallpaper.id,
    );

    if (isInList) {
      await SupabaseService.instance.removeFromWishlist(userId, wallpaper.id);
    } else {
      await SupabaseService.instance.addToWishlist(userId, wallpaper.id);
    }

    onComplete?.call();
  }

  /// Called when auth state changes to signed in.
  /// Executes any pending wishlist add with the REAL wallpaper object.
  static void onAuthSuccess() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _pendingWallpaper != null) {
      _toggleWishlist(user.id, _pendingWallpaper!, _onPendingComplete);
      _pendingWallpaper = null;
      _onPendingComplete = null;
    }
  }
}
