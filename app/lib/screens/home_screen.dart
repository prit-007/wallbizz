import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/theme_config.dart';
import '../widgets/category_tabs.dart';
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

  static const _navItems = [
    _DockItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'DISCOVER'),
    _DockItem(
      Icons.favorite_outline_rounded,
      Icons.favorite_rounded,
      'ARCHIVE',
    ),
    _DockItem(Icons.download_outlined, Icons.download_rounded, 'VAULT'),
    _DockItem(Icons.tune_outlined, Icons.tune_rounded, 'SYSTEM'),
  ];

  @override
  void dispose() {
    for (final c in _scrollControllers) {
      c.dispose();
    }
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            if (_tabWidgets[0] != null || _currentNavIndex == 0)
              Offstage(
                offstage: _currentNavIndex != 0,
                child: RepaintBoundary(child: _buildHomeTab(bottomInset + 90)),
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
        ),
      ),
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

  Widget _buildHomeTab(double bottomPadding) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final horizontalPadding = isCompact ? 20.0 : 32.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                        'WALLBIZZ',
                        style: GoogleFonts.oswald(
                          fontSize: isCompact ? 42 : 56,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                          letterSpacing: 4.5,
                          height: 1.0,
                        ),
                      )
                      .animate()
                      .fade(duration: 600.ms)
                      .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 8),
                  Container(width: 48, height: 3, color: cs.primary)
                      .animate()
                      .fade(delay: 200.ms)
                      .scaleX(
                        begin: 0,
                        end: 1,
                        alignment: Alignment.centerLeft,
                      ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child:
                  GestureDetector(
                        key: const Key('search_bar'),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SearchScreen(),
                            ),
                          );
                        },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(0),
                            border: Border.all(
                              color: vk.glassBorder,
                              width: 1.5,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 16 : 24,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'EXPLORE CURATED ARCHIVES...',
                                style: GoogleFonts.inter(
                                  color: vk.onSurfaceSubtle,
                                  fontSize: isCompact ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.search_rounded,
                                color: cs.onSurface,
                                size: isCompact ? 20 : 24,
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fade(delay: 300.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
            ),
            const SizedBox(height: 24),

            CategoryTabs(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = category);
              },
            ).animate().fade(delay: 400.ms),

            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: StaggeredGrid(
                  key: ValueKey(_selectedCategory),
                  category: _selectedCategory,
                  scrollController: _scrollControllers[0],
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
            ),
          ],
        );
      },
    );
  }
}

class _DockItem {
  final IconData icon;
  final IconData selectedIcon;
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

    return ValueListenableBuilder(
      valueListenable: Hive.box('downloads').listenable(),
      builder: (context, Box box, _) {
        final downloadCount = box.length;

        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: bottomInset > 0 ? bottomInset + 8 : 24,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                height: 72,
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
                  child: Icon(iconData, size: 22, color: iconColor),
                )
              else
                Icon(iconData, size: 22, color: iconColor),
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
