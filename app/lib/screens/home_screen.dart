import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/backend_config.dart';
import '../config/responsive_config.dart';
import '../config/theme_config.dart';
import '../widgets/category_tabs.dart';
import '../widgets/hover_builder.dart';
import '../widgets/staggered_grid.dart';
import 'search_screen.dart';
import 'wishlist_screen.dart';
import 'settings_screen.dart';
import 'downloads_screen.dart';
import 'wallpaper_swiper_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'trending';
  int _currentNavIndex = 0;
  final List<Widget?> _tabWidgets = List.filled(4, null);
  final List<ScrollController> _scrollControllers = [
    ScrollController(),
    ScrollController(),
    ScrollController(),
    ScrollController(),
  ];
  final FocusNode _searchFocusNode = FocusNode();
  Key _landscapeKey = UniqueKey();
  bool _lastWasLandscapeCompact = false;

  static const _navItems = [
    _DockItem(
      HugeIcons.strokeRoundedGridView,
      HugeIcons.strokeRoundedGridView,
      'DISCOVER',
    ),
    _DockItem(
      HugeIcons.strokeRoundedFavourite,
      HugeIcons.strokeRoundedFavourite,
      'ARCHIVE',
    ),
    _DockItem(
      HugeIcons.strokeRoundedDownload02,
      HugeIcons.strokeRoundedDownload01,
      'VAULT',
    ),
    _DockItem(
      HugeIcons.strokeRoundedSettings02,
      HugeIcons.strokeRoundedSettings01,
      'SYSTEM',
    ),
  ];

  @override
  void dispose() {
    for (final c in _scrollControllers) {
      c.dispose();
    }
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _scrollToTop(int index) {
    final c = _scrollControllers[index];
    if (c.hasClients) {
      c.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = context.isDesktop;

    return Scaffold(
      extendBody: !desktop,
      body: desktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    final vk = context.vivek;
    final cs = Theme.of(context).colorScheme;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        if ((event.logicalKey == LogicalKeyboardKey.keyF &&
                HardwareKeyboard.instance.isControlPressed) ||
            event.logicalKey == LogicalKeyboardKey.slash) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SearchScreen(backendBase: BackendConfig.baseUrl),
            ),
          );
          return KeyEventResult.handled;
        }
        final keys = [
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit2,
          LogicalKeyboardKey.digit3,
          LogicalKeyboardKey.digit4,
        ];
        final idx = keys.indexOf(event.logicalKey);
        if (idx >= 0 && idx < _navItems.length) {
          HapticFeedback.lightImpact();
          if (idx == _currentNavIndex) {
            _scrollToTop(idx);
          } else {
            setState(() {
              _tabWidgets[idx] ??= _buildTabContent(idx);
              _currentNavIndex = idx;
            });
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentNavIndex,
            onDestinationSelected: (index) {
              HapticFeedback.lightImpact();
              if (index == _currentNavIndex) {
                _scrollToTop(index);
              } else {
                setState(() {
                  _tabWidgets[index] ??= _buildTabContent(index);
                  _currentNavIndex = index;
                });
              }
            },
            backgroundColor: vk.surfaceContainer,
            indicatorColor: cs.primary,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'WB',
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                  letterSpacing: 2,
                ),
              ),
            ),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: IconThemeData(color: cs.onPrimary, size: 22),
            unselectedIconTheme: IconThemeData(
              color: cs.onSurface.withValues(alpha: 0.5),
              size: 22,
            ),
            selectedLabelTextStyle: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
            unselectedLabelTextStyle: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
            destinations: _navItems
                .map(
                  (item) => NavigationRailDestination(
                    icon: HugeIcon(icon: item.icon),
                    selectedIcon: HugeIcon(icon: item.selectedIcon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: vk.glassBorder.withValues(alpha: 0.2),
          ),
          Expanded(child: _buildTabBody()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      extendBody: true,
      body: SafeArea(bottom: false, child: _buildTabBody()),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentNavIndex,
        navItems: _navItems,
        onTap: (index) {
          HapticFeedback.lightImpact();
          if (index == _currentNavIndex) {
            _scrollToTop(index);
          } else {
            setState(() {
              _tabWidgets[index] ??= _buildTabContent(index);
              _currentNavIndex = index;
            });
          }
        },
      ),
    );
  }

  Widget _buildTabBody() {
    return Stack(
      children: [
        if (_tabWidgets[0] != null || _currentNavIndex == 0)
          Offstage(
            offstage: _currentNavIndex != 0,
            child: RepaintBoundary(child: _buildHomeTab()),
          ),
        if (_tabWidgets[1] != null)
          Offstage(
            offstage: _currentNavIndex != 1,
            child: RepaintBoundary(child: _tabWidgets[1]!),
          ),
        if (_tabWidgets[2] != null)
          Offstage(
            offstage: _currentNavIndex != 2,
            child: RepaintBoundary(child: _tabWidgets[2]!),
          ),
        if (_tabWidgets[3] != null)
          Offstage(
            offstage: _currentNavIndex != 3,
            child: RepaintBoundary(child: _tabWidgets[3]!),
          ),
      ],
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 1:
        return const WishlistScreen();
      case 2:
        return const DownloadsScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHomeTab() {
    final desktop = context.isDesktop;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isLandscapeCompact = isLandscape && constraints.maxHeight <= 350;
        final horizontalPadding = isCompact ? 20.0 : 32.0;
        final bottomPadding = desktop ? 24.0 : 90.0;

        if (_lastWasLandscapeCompact != isLandscapeCompact) {
          _lastWasLandscapeCompact = isLandscapeCompact;
          _landscapeKey = UniqueKey();
        }

        final brandFontSize = isLandscapeCompact
            ? 28.0
            : (isLandscape ? 32.0 : (isCompact ? 42.0 : 56.0));
        final topPadding = isLandscapeCompact
            ? 8.0
            : (isLandscape ? 12.0 : 24.0);
        final spacingAfterBrand = isLandscapeCompact
            ? 8.0
            : (isLandscape ? 12.0 : 24.0);
        final showAccentBar = !isLandscapeCompact;
        final searchBarHeight = isLandscapeCompact ? 44.0 : 56.0;
        final searchFontSize = isLandscapeCompact
            ? 11.0
            : (isCompact ? 12.0 : 14.0);
        final searchIconSize = isLandscapeCompact
            ? 18.0
            : (isCompact ? 20.0 : 24.0);

        final expandedHeight = isLandscapeCompact
            ? 44.0 + 54.0
            : (isLandscape
                  ? 12.0 + 32.0 + 8.0 + 3.0 + 12.0 + 56.0 + 12.0 + 54.0
                  : 24.0 + 42.0 + 8.0 + 3.0 + 24.0 + 56.0 + 24.0 + 54.0);

        final content = CustomScrollView(
          controller: _scrollControllers[0],
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: expandedHeight,
              toolbarHeight: 0,
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: KeyedSubtree(
                  key: _landscapeKey,
                  child: _buildBrandHeader(
                    cs: Theme.of(context).colorScheme,
                    horizontalPadding: horizontalPadding,
                    topPadding: topPadding,
                    brandFontSize: brandFontSize,
                    spacingAfterBrand: spacingAfterBrand,
                    showAccentBar: showAccentBar,
                    searchBarHeight: searchBarHeight,
                    searchFontSize: searchFontSize,
                    searchIconSize: searchIconSize,
                    isCompact: isCompact,
                    isLandscapeCompact: isLandscapeCompact,
                    isLandscape: isLandscape,
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(54),
                child: CategoryTabs(
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = category);
                  },
                ).animate().fade(delay: 400.ms),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              sliver: StaggeredGrid(
                key: ValueKey(_selectedCategory),
                category: _selectedCategory,
                scrollController: _scrollControllers[0],
                sliverMode: true,
                onWallpaperTap: (wallpaper, allWallpapers) {
                  final index = allWallpapers.indexWhere(
                    (w) => w.id == wallpaper.id,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WallpaperSwiperScreen(
                        wallpapers: allWallpapers,
                        initialIndex: index >= 0 ? index : 0,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );

        if (!desktop) return content;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ResponsiveConfig.maxContentWidth,
            ),
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildBrandHeader({
    required ColorScheme cs,
    required double horizontalPadding,
    required double topPadding,
    required double brandFontSize,
    required double spacingAfterBrand,
    required bool showAccentBar,
    required double searchBarHeight,
    required double searchFontSize,
    required double searchIconSize,
    required bool isCompact,
    required bool isLandscapeCompact,
    required bool isLandscape,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                    'WALLBIZZ',
                    style: GoogleFonts.oswald(
                      fontSize: brandFontSize,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                      letterSpacing: 4.5,
                      height: 1.0,
                    ),
                  )
                  .animate()
                  .fade(duration: 600.ms)
                  .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
              if (showAccentBar) ...[
                const SizedBox(height: 8),
                Container(width: 48, height: 3, color: cs.primary)
                    .animate()
                    .fade(delay: 200.ms)
                    .scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft),
              ],
              SizedBox(height: spacingAfterBrand),
            ],
          ),
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: context.isDesktop
              ? _buildInlineSearch(horizontalPadding)
              : _buildTapSearch(
                  isCompact,
                  horizontalPadding,
                  searchBarHeight: searchBarHeight,
                  searchFontSize: searchFontSize,
                  searchIconSize: searchIconSize,
                ),
        ),
        SizedBox(height: isLandscapeCompact ? 0 : (isLandscape ? 12 : 24)),
      ],
    );
  }

  Widget _buildTapSearch(
    bool isCompact,
    double horizontalPadding, {
    double searchBarHeight = 56,
    double searchFontSize = 12,
    double searchIconSize = 20,
  }) {
    final vk = context.vivek;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
          key: const Key('search_bar'),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SearchScreen(backendBase: BackendConfig.baseUrl),
              ),
            );
          },
          child: Container(
            height: searchBarHeight,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: vk.glassBorder, width: 1.5),
            ),
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24),
            child: Row(
              children: [
                Text(
                  'EXPLORE CURATED ARCHIVES...',
                  style: GoogleFonts.inter(
                    color: vk.onSurfaceSubtle,
                    fontSize: searchFontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: cs.onSurface,
                  size: searchIconSize,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fade(delay: 300.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildInlineSearch(double horizontalPadding) {
    final vk = context.vivek;
    final cs = Theme.of(context).colorScheme;

    return HoverBuilder(
          builder: (context, isHovered) {
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        SearchScreen(backendBase: BackendConfig.baseUrl),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                decoration: BoxDecoration(
                  color: isHovered
                      ? vk.surfaceContainerHigh
                      : vk.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHovered ? cs.primary : vk.glassBorder,
                    width: isHovered ? 1.5 : 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: isHovered ? cs.primary : vk.onSurfaceSubtle,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Search wallpapers...',
                      style: GoogleFonts.inter(
                        color: vk.onSurfaceSubtle,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: vk.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: vk.glassBorder.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '/',
                        style: GoogleFonts.inter(
                          color: vk.onSurfaceDim,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        )
        .animate()
        .fade(delay: 300.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }
}

class _DockItem {
  final dynamic icon;
  final dynamic selectedIcon;
  final String label;
  const _DockItem(this.icon, this.selectedIcon, this.label);
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_DockItem> navItems;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.navItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vk = context.vivek;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final barHeight = isLandscape ? 48.0 : 72.0;
    final barHPadding = isLandscape ? 48.0 : 24.0;

    return ValueListenableBuilder(
      valueListenable: Hive.box('downloads').listenable(),
      builder: (context, Box box, _) {
        final downloadCount = box.length;

        return Padding(
          padding: EdgeInsets.only(
            left: barHPadding,
            right: barHPadding,
            bottom: isLandscape
                ? (bottomInset > 0 ? bottomInset + 4 : 12)
                : (bottomInset > 0 ? bottomInset + 8 : 24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isLandscape ? 12 : 16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: vk.surfaceContainer.withValues(alpha: 0.7),
                  border: Border.all(color: vk.glassBorder, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(navItems.length, (i) {
                    final item = navItems[i];
                    final isSelected = currentIndex == i;
                    final isDownloadTab = i == 2;

                    return _NavBarItem(
                      item: item,
                      isSelected: isSelected,
                      isDownloadTab: isDownloadTab,
                      downloadCount: downloadCount,
                      onTap: () => onTap(i),
                    );
                  }),
                ),
              ),
            ),
          ),
        ).animate().slideY(
          begin: 1.0,
          end: 0,
          curve: Curves.easeOutExpo,
          duration: 800.ms,
        );
      },
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final _DockItem item;
  final bool isSelected;
  final bool isDownloadTab;
  final int downloadCount;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.isDownloadTab,
    required this.downloadCount,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = widget.isSelected
        ? cs.surface
        : cs.onSurface.withValues(alpha: 0.6);
    final iconData = widget.isSelected
        ? widget.item.selectedIcon
        : widget.item.icon;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSelected ? 20 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected ? cs.onSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isDownloadTab)
                Badge(
                  isLabelVisible: widget.downloadCount > 0,
                  label: Text(
                    widget.downloadCount > 99
                        ? '99+'
                        : '${widget.downloadCount}',
                    style: TextStyle(
                      color: widget.isSelected ? cs.onSurface : cs.surface,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: widget.isSelected
                      ? cs.surface
                      : cs.onSurface,
                  child: HugeIcon(icon: iconData, size: 22, color: iconColor),
                )
              else
                HugeIcon(icon: iconData, size: 22, color: iconColor),
              if (widget.isSelected) ...[
                const SizedBox(width: 10),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: widget.isSelected ? 1.0 : 0.0,
                  child: Text(
                    widget.item.label,
                    style: GoogleFonts.inter(
                      color: cs.surface,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
