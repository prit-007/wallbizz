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
  final Function(Wallpaper)? onWallpaperTap;

  const StaggeredGrid({
    super.key,
    this.category,
    this.onWallpaperTap,
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
      if (mounted) {
        setState(() {
          _wishlistedIds.addAll(list.map((w) => w.id));
        });
      }
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
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    setState(() {
      _wallpapers.clear();
      _page = 0;
      _hasMore = true;
    });
    await _loadWallpapers();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_wallpapers.isEmpty && _isLoading) {
      return _buildLoadingSkeleton();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 900
              ? 4
              : constraints.maxWidth > 600
                  ? 3
                  : 2;

          return MasonryGridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: const EdgeInsets.all(8),
            controller: _scrollController,
            itemCount: _wallpapers.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _wallpapers.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  ),
                );
              }

              final wp = _wallpapers[index];
              return WallpaperCard(
                wallpaper: wp,
                isWishlisted: _wishlistedIds.contains(wp.id),
                onTap: () => widget.onWallpaperTap?.call(wp),
                onHeartTap: () => _onHeartTap(wp),
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
        final heights = [200.0, 280.0, 240.0, 320.0, 180.0, 260.0];

        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.all(8),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crossAxisCount * 3,
          itemBuilder: (context, index) {
            return Container(
              height: heights[index % heights.length],
              decoration: BoxDecoration(
                color: vk.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1200.ms, color: vk.shimmerHighlight);
          },
        );
      },
    );
  }
}
