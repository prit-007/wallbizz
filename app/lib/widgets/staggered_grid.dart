import 'package:flutter/material.dart';
import '../models/wallpaper.dart';
import '../widgets/wallpaper_card.dart';
import '../services/supabase_service.dart';

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
  int _page = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadWallpapers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(StaggeredGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _resetAndLoad();
    }
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
    if (_wallpapers.isEmpty && _isLoading) {
      return _buildLoadingSkeleton();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 2;
          if (constraints.maxWidth > 900) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth > 600) {
            crossAxisCount = 3;
          }

          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.6,
            ),
            itemCount: _wallpapers.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _wallpapers.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                );
              }

              return WallpaperCard(
                wallpaper: _wallpapers[index],
                onTap: () => widget.onWallpaperTap?.call(_wallpapers[index]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.6,
          ),
          itemCount: 10,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
            );
          },
        );
      },
    );
  }
}
