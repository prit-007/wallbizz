import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallpaper.dart';
import '../services/wallhaven_search.dart';
import '../widgets/wallpaper_card.dart';
import '../widgets/auth_bottom_sheet.dart';
import '../services/wallpaper_actions.dart';
import 'detail_screen.dart';
import '../config/theme_config.dart';

class SearchScreen extends StatefulWidget {
  final dynamic httpClient;
  final bool isAuthenticated;
  final String backendBase;
  final String? accessToken;

  const SearchScreen({
    super.key,
    this.httpClient,
    this.isAuthenticated = false,
    this.backendBase = 'https://wallbizz-production.up.railway.app',
    this.accessToken,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late WallhavenSearch _search;

  final List<Wallpaper> _results = [];
  int _page = 0;
  int _lastPage = 0;
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  String _purity = '100';
  String _sorting = 'date_added';
  String _topRange = '';
  String _categories = '';
  String _ratios = '';

  static const List<String> _trendingTags = [
    'Cyberpunk',
    'Studio Ghibli',
    'Amoled',
    'Neon City',
    'Minimalist',
    'Pixel Art',
    'Space',
    'Gothic',
  ];

  @override
  void initState() {
    super.initState();
    _search = WallhavenSearch(httpClient: widget.httpClient);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSearch() {
    _focusNode.unfocus();
    _searchQuery(reset: true);
  }

  bool get _isAuthed {
    if (widget.isAuthenticated) return true;
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  String? get _authToken {
    if (widget.accessToken != null) return widget.accessToken;
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> _searchQuery({bool reset = false}) async {
    if (_isLoading) return;
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    if (reset) {
      setState(() {
        if (_results.isEmpty) _hasSearched = true;
        _results.clear();
        _page = 0;
        _lastPage = 0;
        _errorMessage = null;
      });
    }

    final needsAuth = _purity != '100';
    if (needsAuth && !_isAuthed) {
      if (mounted) showAuthBottomSheet(context);
      return;
    }

    setState(() => _isLoading = true);

    SearchResult result;
    if (needsAuth) {
      final token = _authToken;
      if (token == null) {
        if (mounted) showAuthBottomSheet(context);
        setState(() => _isLoading = false);
        return;
      }
      result = await _search.searchAuthenticated(
        query: query,
        page: _page + 1,
        token: token,
        backendBase: widget.backendBase,
        purity: _purity,
        sorting: _sorting,
        topRange: _topRange,
        categories: _categories.isNotEmpty ? _categories : null,
        ratios: _ratios.isNotEmpty ? _ratios : null,
      );
    } else {
      result = await _search.searchPublic(
        query: query,
        page: _page + 1,
        purity: _purity,
        sorting: _sorting,
        topRange: _topRange,
        categories: _categories.isNotEmpty ? _categories : null,
        ratios: _ratios.isNotEmpty ? _ratios : null,
        backendBase: widget.backendBase,
      );
    }

    if (mounted) {
      setState(() {
        _hasSearched = true;
        _errorMessage = result.error;
        _results.addAll(result.wallpapers);
        _page = result.currentPage > 0 ? result.currentPage : _page + 1;
        _lastPage = result.lastPage;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _page >= _lastPage || _lastPage == 0) return;
    await _searchQuery();
  }

  void _setPurity(String value) {
    setState(() => _purity = value);
    if (_controller.text.trim().isNotEmpty) {
      _searchQuery(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilters(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            key: const Key('back_button'),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: vk.surfaceContainer,
              padding: const EdgeInsets.all(12),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: vk.surfaceContainer,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                        color: vk.glassBorder.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: vk.onSurfaceSubtle, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      onSubmitted: (_) => _onSearch(),
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.inter(color: cs.onSurface, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search wallpapers...',
                        hintStyle: GoogleFonts.inter(color: vk.onSurfaceFaint, fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.cancel_rounded, color: vk.onSurfaceFaint, size: 18),
                      ),
                    ),
                  GestureDetector(
                    onTap: _onSearch,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_rounded, color: cs.onPrimary, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildPurityChip('SFW', '100', const Key('purity_sfw'), true, Icons.check_circle_rounded),
              const SizedBox(width: 8),
              _buildPurityChip('Sketchy', '110', const Key('purity_sketchy'), _isAuthed, _isAuthed ? Icons.remove_red_eye_rounded : Icons.lock_rounded),
              const SizedBox(width: 8),
              _buildPurityChip('NSFW', '111', const Key('purity_nsfw'), _isAuthed, _isAuthed ? Icons.explicit_rounded : Icons.lock_rounded),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildDropdown<String>(
                value: _sorting,
                label: 'Sort',
                items: const [
                  DropdownMenuItem(value: 'toplist', child: Text('Toplist')),
                  DropdownMenuItem(value: 'date_added', child: Text('Latest')),
                  DropdownMenuItem(value: 'views', child: Text('Views')),
                  DropdownMenuItem(value: 'favorites', child: Text('Favorites')),
                  DropdownMenuItem(value: 'random', child: Text('Random')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _sorting = v);
                    if (_hasSearched) _searchQuery(reset: true);
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildDropdown<String>(
                value: _topRange,
                label: 'Range',
                items: const [
                  DropdownMenuItem(value: '', child: Text('All Time')),
                  DropdownMenuItem(value: '1d', child: Text('1 Day')),
                  DropdownMenuItem(value: '1w', child: Text('1 Week')),
                  DropdownMenuItem(value: '1M', child: Text('1 Month')),
                  DropdownMenuItem(value: '1y', child: Text('1 Year')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _topRange = v);
                    if (_hasSearched) _searchQuery(reset: true);
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildDropdown<String>(
                value: _categories.isEmpty ? 'all' : _categories,
                label: 'Category',
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Categories')),
                  DropdownMenuItem(value: '100', child: Text('General')),
                  DropdownMenuItem(value: '010', child: Text('Anime')),
                  DropdownMenuItem(value: '001', child: Text('People')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _categories = v == 'all' ? '' : v);
                    if (_hasSearched) _searchQuery(reset: true);
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildDropdown<String>(
                value: _ratios.isEmpty ? 'all' : _ratios,
                label: 'Ratio',
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Ratios')),
                  DropdownMenuItem(value: '16x9', child: Text('16:9')),
                  DropdownMenuItem(value: '9x16', child: Text('9:16')),
                  DropdownMenuItem(value: '1x1', child: Text('1:1')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _ratios = v == 'all' ? '' : v);
                    if (_hasSearched) _searchQuery(reset: true);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurityChip(String label, String value, Key key, bool enabled, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final isSelected = _purity == value;

    return GestureDetector(
      onTap: enabled ? () => _setPurity(value) : () => showAuthBottomSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : (enabled ? vk.surfaceContainer : vk.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? cs.primary : vk.glassBorder.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? cs.onPrimary : (enabled ? vk.onSurfaceSubtle : vk.onSurfaceDim),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? cs.onPrimary : (enabled ? cs.onSurface : vk.onSurfaceDim),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: vk.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: vk.glassBorder.withValues(alpha: 0.12), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: true,
          dropdownColor: vk.surfaceContainer,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: vk.onSurfaceSubtle, size: 18),
          style: GoogleFonts.inter(color: cs.onSurface, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    if (!_hasSearched) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'POPULAR SEARCHES',
              style: GoogleFonts.oswald(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: vk.onSurfaceSubtle,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _trendingTags.map((tag) {
                return GestureDetector(
                  onTap: () {
                    _controller.text = tag;
                    _onSearch();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: vk.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                  color: vk.glassBorder.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: GoogleFonts.inter(
                        color: cs.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ).animate().fade(duration: 400.ms);
    }

    if (_results.isEmpty && _isLoading) {
      return _buildSkeletonGrid();
    }

    if (_results.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _errorMessage != null ? cs.errorContainer : vk.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _errorMessage != null ? Icons.error_outline_rounded : Icons.search_off_rounded,
                  size: 38,
                  color: _errorMessage != null ? cs.error : vk.onSurfaceDim,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage != null ? 'SEARCH FAILED' : 'NO RESULTS FOUND',
                style: GoogleFonts.oswald(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Try adjusting your search terms or filters to find what you are looking for.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: vk.onSurfaceSubtle,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ).animate().fade(duration: 400.ms);
    }

    return LayoutBuilder(
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          controller: _scrollController,
          itemCount: _results.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _results.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2),
                ),
              );
            }
            return WallpaperCard(
              wallpaper: _results[index],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(wallpaper: _results[index]),
                  ),
                );
              },
              onHeartTap: () => WallpaperActions.handleHeartTap(
                context,
                _results[index],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    final vk = context.vivek;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;
        final heights = [220.0, 280.0, 240.0, 310.0, 190.0, 260.0];

        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          padding: const EdgeInsets.all(12),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crossAxisCount * 3,
          itemBuilder: (context, index) {
            return Container(
              height: heights[index % heights.length],
              decoration: BoxDecoration(
                color: vk.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms, color: vk.shimmerHighlight);
          },
        );
      },
    );
  }
}
