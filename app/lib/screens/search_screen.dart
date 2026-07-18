import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallpaper.dart';
import '../services/wallhaven_search.dart';
import '../widgets/wallpaper_card.dart';
import '../widgets/auth_bottom_sheet.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final dynamic httpClient;
  final bool isAuthenticated;
  final String backendBase;
  final String? accessToken;

  const SearchScreen({
    super.key,
    this.httpClient,
    this.isAuthenticated = false,
    this.backendBase = 'http://localhost:3000',
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
  String _sorting = 'toplist';
  String _topRange = '3M';
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
    return Scaffold(
      backgroundColor: Colors.black,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            key: const Key('back_button'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              onSubmitted: (_) => _onSearch(),
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search wallpapers...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        key: const Key('clear_button'),
                        icon: const Icon(Icons.clear, color: Colors.white38, size: 20),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      ),
                    IconButton(
                      key: const Key('search_button'),
                      icon: const Icon(Icons.search, color: Colors.white, size: 20),
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
    final isSelected = _purity == value;
    return GestureDetector(
      onTap: enabled ? () => _setPurity(value) : null,
      child: ChoiceChip(
        key: key,
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.white,
        backgroundColor: enabled ? Colors.grey[900] : Colors.grey[800],
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.black
              : enabled
                  ? Colors.white
                  : Colors.white24,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        isDense: true,
        dropdownColor: Colors.grey[900],
        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        hint: Text(label, style: const TextStyle(color: Colors.white54)),
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched) {
      return const Center(
        child: Text(
          'Search millions of wallpapers',
          style: TextStyle(color: Colors.white38, fontSize: 16),
        ),
      );
    }

    if (_results.isEmpty && _isLoading) {
      return _buildSkeletonGrid();
    }

    if (_results.isEmpty && !_isLoading) {
      return const Center(
        child: Text(
          'No wallpapers found',
          style: TextStyle(color: Colors.white38, fontSize: 16),
        ),
      );
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
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: Colors.white),
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
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
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
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1200.ms, color: Colors.white10);
          },
        );
      },
    );
  }
}
