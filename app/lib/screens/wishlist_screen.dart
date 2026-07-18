import 'dart:async';
import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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

    if (!_isLoggedIn) {
      return _buildGuestView();
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: cs.primary),
      );
    }

    if (_wishlist.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: _checkAuthAndLoad,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 900
              ? 4
              : constraints.maxWidth > 600
                  ? 3
                  : 2;

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
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
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    await SupabaseService.instance.removeFromWishlist(
                      user.id,
                      wallpaper.id,
                    );
                    setState(() => _wishlist.removeAt(index));
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: wallpaper.aspectRatio,
                    child: NetworkImageWidget(
                      imageUrl: wallpaper.urlThumb,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: vk.onSurfaceDim),
          const SizedBox(height: 24),
          Text(
            'Sign in to view your collection',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => showAuthBottomSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: vk.onSurfaceDim),
          const SizedBox(height: 24),
          Text(
            'No wallpapers saved yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart icon to start your collection.',
            style: TextStyle(fontSize: 14, color: vk.onSurfaceSubtle),
          ),
        ],
      ),
    );
  }
}
