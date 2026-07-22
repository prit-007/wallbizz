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

  String _purity = '100';
  String _sorting = 'date_added';
  String _topRange = '';
  String _categories = '';
  String _ratios = '';

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
      });
    }

    final needsAuth = _purity != '100';
    if (needsAuth) {
      if (!_isAuthed) {
        if (mounted) showAuthBottomSheet(context);
        return;
      }
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
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            key: const Key('back_button'),
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              onSubmitted: (_) => _onSearch(),
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Search wallpapers...',
                hintStyle: TextStyle(color: vk.onSurfaceFaint),
                filled: true,
                fillColor: vk.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: vk.onSurfaceFaint, size: 20),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        key: const Key('clear_button'),
                        icon: Icon(Icons.clear, color: vk.onSurfaceFaint, size: 20),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      ),
                    IconButton(
                      key: const Key('search_button'),
                      icon: Icon(Icons.search, color: cs.onSurface, size: 20),
                      onPressed: _onSearch,
                    ),
                  ],
                ),
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
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildPurityChip('SFW', '100', Key('purity_sfw'), true),
              const SizedBox(width: 8),
              _buildPurityChip(
                  'Sketchy', '110', Key('purity_sketchy'), _isAuthed),
              const SizedBox(width: 8),
              _buildPurityChip(
                  'NSFW', '111', Key('purity_nsfw'), _isAuthed),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildDropdown<String>(
                value: _sorting,
                label: 'Sort',
                items: const [
                  DropdownMenuItem(value: 'toplist', child: Text('Toplist')),
                  DropdownMenuItem(value: 'date_added', child: Text('Latest')),
                  DropdownMenuItem(value: 'views', child: Text('Views')),
                  DropdownMenuItem(
                      value: 'favorites', child: Text('Favorites')),
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
                  DropdownMenuItem(value: '3d', child: Text('3 Days')),
                  DropdownMenuItem(value: '1w', child: Text('1 Week')),
                  DropdownMenuItem(value: '1M', child: Text('1 Month')),
                  DropdownMenuItem(value: '3M', child: Text('3 Months')),
                  DropdownMenuItem(value: '6M', child: Text('6 Months')),
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
                  DropdownMenuItem(value: 'all', child: Text('All')),
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
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: '16x9', child: Text('16:9')),
                  DropdownMenuItem(value: '9x16', child: Text('9:16')),
                  DropdownMenuItem(value: '16x10', child: Text('16:10')),
                  DropdownMenuItem(value: '4x3', child: Text('4:3')),
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

  Widget _buildPurityChip(
      String label, String value, Key key, bool enabled) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final isSelected = _purity == value;
    return GestureDetector(
      onTap: enabled ? () => _setPurity(value) : null,
      child: ChoiceChip(
        key: key,
        label: Text(label),
        selected: isSelected,
        selectedColor: cs.onSurface,
        backgroundColor: enabled ? vk.surfaceContainer : vk.surfaceContainerHigh,
        labelStyle: TextStyle(
          color: isSelected
              ? cs.surface
              : enabled
                  ? cs.onSurface
                  : vk.onSurfaceDim,
          fontWeight: FontWeight.w600,
        ),
        onSelected: enabled ? (_) => _setPurity(value) : (_) {},
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: vk.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        isDense: true,
        dropdownColor: vk.surfaceContainer,
        style: GoogleFonts.inter(color: cs.onSurface, fontSize: 13),
        hint: Text(label, style: TextStyle(color: vk.onSurfaceSubtle)),
      ),
    );
  }

  Widget _buildBody() {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    if (!_hasSearched) {
      return Center(
        child: Text(
          'Search millions of wallpapers',
          style: TextStyle(color: vk.onSurfaceFaint, fontSize: 16),
        ),
      );
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
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: vk.surfaceContainer,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: vk.onSurfaceDim,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No wallpapers found',
                style: GoogleFonts.oswald(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term, adjust your filters, or explore our curated categories.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: vk.onSurfaceSubtle,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  _controller.clear();
                  setState(() {
                    _results.clear();
                    _hasSearched = false;
                  });
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Clear filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  side: BorderSide(color: vk.glassBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fade(duration: 400.ms).slideY(begin: 0.2, end: 0);
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
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          padding: const EdgeInsets.all(8),
          controller: _scrollController,
          itemCount: _results.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _results.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: cs.primary),
                ),
              );
            }
            return WallpaperCard(
              wallpaper: _results[index],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        DetailScreen(wallpaper: _results[index]),
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
        final heights = [200.0, 280.0, 240.0, 320.0, 180.0, 260.0];

        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
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
