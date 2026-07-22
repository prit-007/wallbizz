import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/theme_config.dart';
import '../widgets/category_tabs.dart';
import '../widgets/staggered_grid.dart';
import 'detail_screen.dart';
import 'search_screen.dart';
import 'wishlist_screen.dart';
import 'settings_screen.dart';
import 'downloads_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'trending';
  int _currentNavIndex = 0;

  static const _navItems = [
    _DockItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Home'),
    _DockItem(Icons.favorite_outline_rounded, Icons.favorite_rounded, 'Collection'),
    _DockItem(Icons.download_outlined, Icons.download_rounded, 'Downloads'),
    _DockItem(Icons.tune_outlined, Icons.tune_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true, // Enables true edge-to-edge content bleeding under the floating dock
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildHomeTab(bottomInset + 80), // Extra padding for the floating bar
            const WishlistScreen(),
            const DownloadsScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentNavIndex,
        navItems: _navItems,
        onTap: (index) => setState(() => _currentNavIndex = index),
      ),
    );
  }

  Widget _buildHomeTab(double bottomPadding) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final horizontalPadding = isCompact ? 16.0 : 24.0;
        final searchBarHeight = isCompact ? 48.0 : 54.0;
        final brandCs = Theme.of(context).colorScheme;
        final brandVk = context.vivek;

        return Column(
          children: [
            // Header Section
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WALLBIZZ',
                        style: GoogleFonts.oswald(
                          fontSize: isCompact ? 24 : 30,
                          fontWeight: FontWeight.bold,
                          color: brandCs.primary,
                          letterSpacing: 3.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'CURATED WALLPAPERS',
                        style: GoogleFonts.inter(
                          fontSize: isCompact ? 10 : 12,
                          fontWeight: FontWeight.w600,
                          color: brandVk.onSurfaceSubtle,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar Trigger
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                10,
                horizontalPadding,
                10,
              ),
              child: GestureDetector(
                key: const Key('search_bar'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchScreen(),
                    ),
                  );
                },
                child: Container(
                  height: searchBarHeight,
                  decoration: BoxDecoration(
                    color: brandVk.surfaceOverlay,
                    borderRadius: BorderRadius.circular(27),
                    border: Border.all(
                      color: brandVk.glassBorder.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 16 : 20,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: brandVk.onSurfaceSubtle,
                        size: isCompact ? 20 : 22,
                      ),
                      SizedBox(width: isCompact ? 12 : 16),
                      Text(
                        'Search wallpapers, anime, art...',
                        style: GoogleFonts.inter(
                          color: brandVk.onSurfaceSubtle,
                          fontSize: isCompact ? 13 : 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Category Filter Bar
            CategoryTabs(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
              },
            ),

            // Main Staggered Grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: StaggeredGrid(
                  key: ValueKey(_selectedCategory),
                  category: _selectedCategory,
                  onWallpaperTap: (wallpaper) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(wallpaper: wallpaper),
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

// Private Dock Data Structure
class _DockItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _DockItem(this.icon, this.selectedIcon, this.label);
}

// Optimized Floating Frosted-Glass Bottom Navigation Bar
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
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ValueListenableBuilder(
      valueListenable: Hive.box('downloads').listenable(),
      builder: (context, Box box, _) {
        final downloadCount = box.length;

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: bottomInset > 0 ? bottomInset + 4 : 16,
          ),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: vk.surfaceContainer.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: vk.glassBorder.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(navItems.length, (i) {
                      final item = navItems[i];
                      final isSelected = currentIndex == i;
                      final isDownloadTab = i == 2;

                      return GestureDetector(
                        onTap: () => onTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSelected ? 16 : 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: cs.primary.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildIcon(
                                item: item,
                                isSelected: isSelected,
                                isDownloadTab: isDownloadTab,
                                downloadCount: downloadCount,
                                cs: cs,
                                vk: vk,
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: isSelected ? 1.0 : 0.0,
                                  child: Text(
                                    item.label,
                                    style: GoogleFonts.inter(
                                      color: cs.onPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon({
    required _DockItem item,
    required bool isSelected,
    required bool isDownloadTab,
    required int downloadCount,
    required ColorScheme cs,
    required dynamic vk,
  }) {
    final iconColor = isSelected ? cs.onPrimary : vk.onSurfaceSubtle;
    final iconData = isSelected ? item.selectedIcon : item.icon;

    if (isDownloadTab) {
      return Badge(
        isLabelVisible: downloadCount > 0,
        label: Text(
          downloadCount > 99 ? '99+' : '$downloadCount',
          style: TextStyle(
            color: isSelected ? cs.primary : cs.onPrimary,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isSelected ? cs.onPrimary : cs.primary,
        child: Icon(iconData, size: 22, color: iconColor),
      );
    }

    return Icon(iconData, size: 22, color: iconColor);
  }
}