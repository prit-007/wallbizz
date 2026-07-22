import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme_config.dart';
import '../models/wallpaper.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_bottom_sheet.dart';
import '../widgets/network_image.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Wallpaper> _wishlist = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (_) => _checkAuthAndLoad(),
    );
    SupabaseService.wishlistNotifier.addListener(_onWishlistChanged);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    SupabaseService.wishlistNotifier.removeListener(_onWishlistChanged);
    super.dispose();
  }

  void _onWishlistChanged() {
    _checkAuthAndLoad();
  }

  Future<void> _checkAuthAndLoad() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (!mounted) return;
    setState(() => _isLoggedIn = user != null);

    if (user != null) {
      final items = await SupabaseService.instance.fetchWishlist(user.id);
      if (mounted) {
        setState(() {
          _wishlist = items;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _wishlist = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    if (!_isLoggedIn) return _buildGuestView();
    if (_isLoading) return Center(child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2));
    if (_wishlist.isEmpty) return _buildEmptyView();

    return RefreshIndicator(
      onRefresh: _checkAuthAndLoad,
      color: cs.primary,
      backgroundColor: cs.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 900
              ? 4
              : constraints.maxWidth > 600
                  ? 3
                  : 2;

          return MasonryGridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: _wishlist.length,
            itemBuilder: (context, index) {
              final wallpaper = _wishlist[index];
              return Dismissible(
                key: Key(wallpaper.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                ),
                onDismissed: (_) async {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    await SupabaseService.instance.removeFromWishlist(user.id, wallpaper.id);
                    setState(() => _wishlist.removeAt(index));
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: wallpaper.aspectRatio,
                    child: NetworkImageWidget(
                      imageUrl: wallpaper.urlThumb,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0, delay: Duration(milliseconds: (index % crossAxisCount) * 50));
            },
          );
        },
      ),
    );
  }

  Widget _buildGuestView() {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: vk.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline_rounded, size: 48, color: vk.onSurfaceDim),
            ),
            const SizedBox(height: 24),
            Text(
              'MEMBERS ONLY',
              style: GoogleFonts.oswald(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to sync and view your curated collection across all your devices.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: vk.onSurfaceSubtle, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => showAuthBottomSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.onSurface,
                foregroundColor: cs.surface,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Sign In Now',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: vk.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite_border_rounded, size: 48, color: vk.onSurfaceDim),
            ),
            const SizedBox(height: 24),
            Text(
              'NO SAVES YET',
              style: GoogleFonts.oswald(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any wallpaper to add it to your personal collection.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: vk.onSurfaceSubtle, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
