import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger/logger.dart';
import '../models/wallpaper.dart';
import '../services/wallhaven_search.dart';
import '../widgets/wallpaper_card.dart';
import '../widgets/auth_bottom_sheet.dart';
import '../services/wallpaper_actions.dart';
import '../services/recent_searches.dart';
import 'wallpaper_swiper_screen.dart';
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
    this.backendBase = 'https://wallbizz.onrender.com',
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
  List<String> _recentSearches = [];
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

  static const List<Map<String, String>> _trendingTags = [
    {'name': 'Cyberpunk', 'icon': '\u{1F916}'},
    {'name': 'Studio Ghibli', 'icon': '\u{1F338}'},
    {'name': 'AMOLED', 'icon': '\u{2B1B}'},
    {'name': 'Neon City', 'icon': '\u{1F303}'},
    {'name': 'Minimalist', 'icon': '\u{1F3A8}'},
    {'name': 'Pixel Art', 'icon': '\u{1F47E}'},
    {'name': 'Space', 'icon': '\u{1F680}'},
    {'name': 'Gothic', 'icon': '\u{1F987}'},
  ];

  @override
  void initState() {
    super.initState();
    _search = WallhavenSearch(httpClient: widget.httpClient);
    _scrollController.addListener(_onScroll);
    _focusNode.addListener(() => setState(() {}));
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final searches = await RecentSearches.load();
    if (mounted) setState(() => _recentSearches = searches);
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
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      RecentSearches.add(query);
      _loadRecentSearches();
    }
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
    logInfo(
      'Searching: "$query" purity=$_purity sort=$_sorting page=${_page + 1}',
      domain: LogDomain.search,
    );

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
      if (result.error != null) {
        logError('Search error: ${result.error}', domain: LogDomain.search);
      } else {
        logInfo(
          'Search results: ${result.wallpapers.length} wallpapers, page ${result.currentPage}/${result.lastPage}',
          domain: LogDomain.search,
        );
      }
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
            _buildFiltersBar(),
            const SizedBox(height: 6),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final isFocused = _focusNode.hasFocus;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: vk.surfaceContainer,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: vk.glassBorder.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: cs.onSurface,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              height: 52,
              decoration: BoxDecoration(
                color: isFocused
                    ? vk.surfaceContainerHigh
                    : vk.surfaceContainer,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isFocused
                      ? cs.primary
                      : vk.glassBorder.withValues(alpha: 0.15),
                  width: isFocused ? 1.5 : 1,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: isFocused ? cs.primary : vk.onSurfaceSubtle,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      onSubmitted: (_) => _onSearch(),
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.inter(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search 4K wallpapers, anime...',
                        hintStyle: GoogleFonts.inter(
                          color: vk.onSurfaceFaint,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
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
                        child: Icon(
                          Icons.cancel_rounded,
                          color: vk.onSurfaceFaint,
                          size: 18,
                        ),
                      ),
                    ),

                  GestureDetector(
                    onTap: _onSearch,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: cs.onPrimary,
                        size: 16,
                      ),
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

  Widget _buildFiltersBar() {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildPurityChip(
                'SFW',
                '100',
                true,
                Icons.verified_user_rounded,
                Colors.greenAccent,
              ),
              const SizedBox(width: 8),
              _buildPurityChip(
                'Sketchy',
                '110',
                _isAuthed,
                _isAuthed ? Icons.remove_red_eye_rounded : Icons.lock_rounded,
                Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              _buildPurityChip(
                'NSFW',
                '111',
                _isAuthed,
                _isAuthed ? Icons.explicit_rounded : Icons.lock_rounded,
                Colors.redAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildFilterCapsule<String>(
                value: _sorting,
                label: 'Sort',
                defaultValue: 'date_added',
                items: const {
                  'toplist': 'Toplist',
                  'date_added': 'Latest',
                  'views': 'Most Viewed',
                  'favorites': 'Most Favorited',
                  'random': 'Random',
                },
                onChanged: (v) {
                  setState(() => _sorting = v);
                  if (_hasSearched) _searchQuery(reset: true);
                },
              ),
              const SizedBox(width: 8),
              _buildFilterCapsule<String>(
                value: _topRange,
                label: 'Range',
                defaultValue: '',
                items: const {
                  '': 'All Time',
                  '1d': 'Past 24h',
                  '1w': 'Past Week',
                  '1M': 'Past Month',
                  '1y': 'Past Year',
                },
                onChanged: (v) {
                  setState(() => _topRange = v);
                  if (_hasSearched) _searchQuery(reset: true);
                },
              ),
              const SizedBox(width: 8),
              _buildFilterCapsule<String>(
                value: _categories.isEmpty ? 'all' : _categories,
                label: 'Category',
                defaultValue: 'all',
                items: const {
                  'all': 'All Types',
                  '100': 'General',
                  '010': 'Anime',
                  '001': 'People',
                },
                onChanged: (v) {
                  setState(() => _categories = v == 'all' ? '' : v);
                  if (_hasSearched) _searchQuery(reset: true);
                },
              ),
              const SizedBox(width: 8),
              _buildFilterCapsule<String>(
                value: _ratios.isEmpty ? 'all' : _ratios,
                label: 'Aspect Ratio',
                defaultValue: 'all',
                items: const {
                  'all': 'All Ratios',
                  '9x16': 'Mobile (9:16)',
                  '16x9': 'Desktop (16:9)',
                  '1x1': 'Square (1:1)',
                },
                onChanged: (v) {
                  setState(() => _ratios = v == 'all' ? '' : v);
                  if (_hasSearched) _searchQuery(reset: true);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurityChip(
    String label,
    String value,
    bool enabled,
    IconData icon,
    Color activeAccent,
  ) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final isSelected = _purity == value;

    return GestureDetector(
      onTap: enabled
          ? () => _setPurity(value)
          : () => showAuthBottomSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeAccent.withValues(alpha: 0.2)
              : (enabled ? vk.surfaceContainer : vk.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeAccent
                : vk.glassBorder.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? activeAccent
                  : (enabled ? vk.onSurfaceSubtle : vk.onSurfaceDim),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? activeAccent
                    : (enabled ? cs.onSurface : vk.onSurfaceDim),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCapsule<T>({
    required T value,
    required String label,
    required T defaultValue,
    required Map<T, String> items,
    required ValueChanged<T> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final isModified = value != defaultValue;
    final displayLabel = items[value] ?? label;

    return GestureDetector(
      onTap: () => _showFilterPickerBottomSheet(
        title: label,
        value: value,
        items: items,
        onSelected: onChanged,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isModified
              ? cs.primary.withValues(alpha: 0.15)
              : vk.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isModified
                ? cs.primary
                : vk.glassBorder.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isModified ? FontWeight.bold : FontWeight.w500,
                color: isModified ? cs.primary : cs.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isModified ? cs.primary : vk.onSurfaceSubtle,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterPickerBottomSheet<T>({
    required String title,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T> onSelected,
  }) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: vk.surfaceContainerHigh.withValues(alpha: 0.9),
              border: Border(
                top: BorderSide(
                  color: vk.glassBorder.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: vk.onSurfaceFaint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                ...items.entries.map((entry) {
                  final isSelected = entry.key == value;
                  return GestureDetector(
                    onTap: () {
                      onSelected(entry.key);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary.withValues(alpha: 0.15)
                            : vk.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? cs.primary : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.value,
                            style: GoogleFonts.inter(
                              color: isSelected ? cs.primary : cs.onSurface,
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: cs.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    if (!_hasSearched) {
      return _buildPreSearchBody();
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
                  color: _errorMessage != null
                      ? cs.errorContainer
                      : vk.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _errorMessage != null
                      ? Icons.error_outline_rounded
                      : Icons.search_off_rounded,
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
                _errorMessage ??
                    'Try adjusting your search terms or filters to find what you are looking for.',
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
            : (constraints.maxWidth > 600 ? 3 : 2);

        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemCount: _results.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _results.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: cs.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            return WallpaperCard(
                  wallpaper: _results[index],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WallpaperSwiperScreen(
                          wallpapers: _results,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  onHeartTap: () =>
                      WallpaperActions.handleHeartTap(context, _results[index]),
                )
                .animate()
                .fade(duration: 350.ms)
                .slideY(
                  begin: 0.1,
                  end: 0,
                  delay: Duration(milliseconds: (index % crossAxisCount) * 40),
                );
          },
        );
      },
    );
  }

  Widget _buildPreSearchBody() {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.history_rounded, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'RECENT SEARCHES',
                  style: GoogleFonts.oswald(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: vk.onSurfaceSubtle,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await RecentSearches.clear();
                    _loadRecentSearches();
                  },
                  child: Text(
                    'CLEAR',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((query) {
                return GestureDetector(
                  onTap: () {
                    _controller.text = query;
                    _onSearch();
                  },
                  onLongPress: () async {
                    await RecentSearches.remove(query);
                    _loadRecentSearches();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: vk.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: vk.glassBorder.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 14,
                          color: vk.onSurfaceSubtle,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          query,
                          style: GoogleFonts.inter(
                            color: cs.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
          ],

          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: cs.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'POPULAR DISCOVERIES',
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: vk.onSurfaceSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _trendingTags.map((tag) {
              return _TrendingTagChip(
                label: tag['name']!,
                icon: tag['icon']!,
                onTap: () {
                  _controller.text = tag['name']!;
                  _onSearch();
                },
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms);
  }

  Widget _buildSkeletonGrid() {
    final vk = context.vivek;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : (constraints.maxWidth > 600 ? 3 : 2);
        final heights = [220.0, 280.0, 240.0, 310.0, 190.0, 260.0];

        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

class _TrendingTagChip extends StatefulWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;

  const _TrendingTagChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_TrendingTagChip> createState() => _TrendingTagChipState();
}

class _TrendingTagChipState extends State<_TrendingTagChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.decelerate,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                '#${widget.label}',
                style: GoogleFonts.inter(
                  color: cs.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
