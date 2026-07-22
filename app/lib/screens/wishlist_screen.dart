import 'dart:async';
import 'dart:ui';
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
import 'detail_screen.dart';

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

  void _removeItemOptimistically(int index, Wallpaper wallpaper) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _wishlist.removeAt(index);
    });

    bool undoClicked = false;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Text(
                    'Removed from collection',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      undoClicked = true;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      setState(() {
                        _wishlist.insert(index, wallpaper);
                      });
                    },
                    child: Text(
                      'UNDO',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 4));
    if (!undoClicked) {
      await SupabaseService.instance.removeFromWishlist(user.id, wallpaper.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 85;

    if (!_isLoggedIn) return _buildGuestView();
    if (_isLoading) return Center(child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ARCHIVE',
                    style: GoogleFonts.oswald(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      letterSpacing: 4,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 40,
                    height: 3,
                    color: cs.primary,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: vk.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: vk.glassBorder, width: 1),
                ),
                child: Text(
                  '${_wishlist.length} ITEMS',
                  style: GoogleFonts.oswald(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface.withValues(alpha: 0.8),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _wishlist.isEmpty
              ? _buildEmptyView()
              : RefreshIndicator(
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
                        padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding),
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        itemCount: _wishlist.length,
                        itemBuilder: (context, index) {
                          final wallpaper = _wishlist[index];
                          return Dismissible(
                            key: Key(wallpaper.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
                            ),
                            onDismissed: (_) => _removeItemOptimistically(index, wallpaper),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DetailScreen(wallpaper: wallpaper),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: AspectRatio(
                                  aspectRatio: wallpaper.aspectRatio,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      NetworkImageWidget(
                                        imageUrl: wallpaper.urlThumb,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        bottom: 0, left: 0, right: 0,
                                        child: Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              color: Colors.black.withValues(alpha: 0.35),
                                              child: Text(
                                                wallpaper.resolution,
                                                style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fade(duration: 350.ms).slideY(begin: 0.1, end: 0, delay: Duration(milliseconds: (index % crossAxisCount) * 40));
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
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
                fontSize: 26,
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
                'SIGN IN NOW',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
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
