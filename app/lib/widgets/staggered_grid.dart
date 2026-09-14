import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/responsive_config.dart';
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
  final bool sliverMode;

  const StaggeredGrid({
    super.key,
    this.category,
    this.onWallpaperTap,
    this.scrollController,
    this.sliverMode = false,
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
  bool _hasError = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _loadWallpapers();
    _loadWishlist();
    _scrollController.addListener(_onScroll);
    SupabaseService.wishlistNotifier.addListener(_onWishlistChanged);
  }

  @override
  void dispose() {
    SupabaseService.wishlistNotifier.removeListener(_onWishlistChanged);
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  void _onWishlistChanged() {
    _loadWishlist();
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
      onToggle: () {
        setState(() {
          if (_wishlistedIds.contains(wallpaper.id)) {
            _wishlistedIds.remove(wallpaper.id);
          } else {
            _wishlistedIds.add(wallpaper.id);
          }
        });
      },
      onComplete: () => SupabaseService.wishlistNotifier.value++,
    );
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
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
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
    if (widget.sliverMode) return _buildSliver();
    return _buildScrollable();
  }

  Widget _buildSliver() {
    if (_wallpapers.isEmpty && _isLoading) {
      return _buildSliverLoadingSkeleton();
    }

    if (_wallpapers.isEmpty && _hasError) {
      return SliverToBoxAdapter(child: _buildErrorWidget());
    }

    return _buildSliverGrid();
  }

  Widget _buildSliverLoadingSkeleton() {
    final vk = context.vivek;
    final crossAxisCount = context.gridColumns;
    final heights = [220.0, 300.0, 250.0, 340.0, 190.0, 280.0];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childCount: crossAxisCount * 2,
        itemBuilder: (context, index) {
          return RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -1.0, end: 1.0),
              duration: Duration(milliseconds: 1200 + (index * 100)),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Container(
                  height: heights[index % heights.length],
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment(value - 0.3, 0),
                      end: Alignment(value + 0.3, 0),
                      colors: [
                        vk.surfaceContainer,
                        vk.shimmerHighlight,
                        vk.surfaceContainer,
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverGrid() {
    final cs = Theme.of(context).colorScheme;

    return SliverMasonryGrid.count(
      crossAxisCount: context.gridColumns,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childCount: _wallpapers.length + (_hasMore ? 1 : 0),
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
        );
      },
    );
  }

  Widget _buildScrollable() {
    final cs = Theme.of(context).colorScheme;

    if (_wallpapers.isEmpty && _isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_wallpapers.isEmpty && _hasError) {
      return _buildErrorWidget();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: cs.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = context.gridColumns;

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
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load wallpapers',
            style: TextStyle(color: cs.onSurface),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _resetAndLoad,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    final vk = context.vivek;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = context.gridColumns;
        final heights = [220.0, 300.0, 250.0, 340.0, 190.0, 280.0];

        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crossAxisCount * 2,
          itemBuilder: (context, index) {
            return RepaintBoundary(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: -1.0, end: 1.0),
                duration: Duration(milliseconds: 1200 + (index * 100)),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Container(
                    height: heights[index % heights.length],
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment(value - 0.3, 0),
                        end: Alignment(value + 0.3, 0),
                        colors: [
                          vk.surfaceContainer,
                          vk.shimmerHighlight,
                          vk.surfaceContainer,
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
