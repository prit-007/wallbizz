import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme_config.dart';
import '../models/wallpaper.dart';
import '../widgets/wallpaper_card.dart';
import '../services/supabase_service.dart';
import '../services/wallpaper_actions.dart';

class StaggeredGrid extends StatefulWidget {
  final String? category;
  final Function(Wallpaper wallpaper, List<Wallpaper> allWallpapers)?
  onWallpaperTap;
  final ScrollController? scrollController;

  const StaggeredGrid({
    super.key,
    this.category,
    this.onWallpaperTap,
    this.scrollController,
  });

  @override
  State<StaggeredGrid> createState() => _StaggeredGridState();
}

class _StaggeredGridState extends State<StaggeredGrid> {
  final List<Wallpaper> _wallpapers = [];
  final Set<String> _wishlistedIds = {};
  int _page = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _loadWallpapers();
    _loadWishlist();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(StaggeredGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _resetAndLoad();
    }
  }

  Future<void> _loadWishlist() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _wishlistedIds.clear();
      return;
    }
    try {
      final list = await SupabaseService.instance.fetchWishlist(user.id);
      if (mounted) setState(() => _wishlistedIds.addAll(list.map((w) => w.id)));
    } catch (_) {}
  }

  void _onHeartTap(Wallpaper wallpaper) {
    WallpaperActions.handleHeartTap(
      context,
      wallpaper,
      onComplete: () {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return;
        setState(() {
          if (_wishlistedIds.contains(wallpaper.id)) {
            _wishlistedIds.remove(wallpaper.id);
          } else {
            _wishlistedIds.add(wallpaper.id);
          }
        });
        SupabaseService.wishlistNotifier.value++;
      },
    );
  }

  @override
  void dispose() {
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  void _resetAndLoad() {
    setState(() {
      _wallpapers.clear();
      _page = 0;
      _hasMore = true;
    });
    _loadWallpapers();
  }

  Future<void> _loadWallpapers() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    final newWallpapers = await SupabaseService.instance.fetchWallpapers(
      category: widget.category,
      page: _page,
    );
    if (mounted) {
      setState(() {
        _wallpapers.addAll(newWallpapers);
        _page++;
        _hasMore = newWallpapers.length == 24;
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadWallpapers();
    }
  }

  Future<void> _onRefresh() async {
    _resetAndLoad();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_wallpapers.isEmpty && _isLoading) {
      return _buildLoadingSkeleton();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: cs.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 900
              ? 4
              : constraints.maxWidth > 600
              ? 3
              : 2;

          return MasonryGridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: _wallpapers.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _wallpapers.length) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: cs.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final wp = _wallpapers[index];
              return RepaintBoundary(
                    child: WallpaperCard(
                      wallpaper: wp,
                      isWishlisted: _wishlistedIds.contains(wp.id),
                      onTap: () => widget.onWallpaperTap?.call(wp, _wallpapers),
                      onHeartTap: () => _onHeartTap(wp),
                    ),
                  )
                  .animate()
                  .fade(duration: 400.ms)
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    delay: Duration(
                      milliseconds: (index % crossAxisCount) * 50,
                    ),
                  );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    final vk = context.vivek;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
            ? 3
            : 2;
        final heights = [220.0, 300.0, 250.0, 340.0, 190.0, 280.0];

        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crossAxisCount * 3,
          itemBuilder: (context, index) {
            return RepaintBoundary(
              child:
                  Container(
                        height: heights[index % heights.length],
                        decoration: BoxDecoration(
                          color: vk.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 1200.ms, color: vk.shimmerHighlight),
            );
          },
        );
      },
    );
  }
}
