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
    _DockItem(Icons.grid_view, Icons.grid_view, 'Home'),
    _DockItem(Icons.favorite_border, Icons.favorite, 'Collection'),
    _DockItem(Icons.download_outlined, Icons.download, 'Downloads'),
    _DockItem(Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    return Scaffold(
      body: SafeArea(
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: Hive.box('downloads').listenable(),
        builder: (context, Box box, _) {
          final count = box.length;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 12,
              left: 16,
              right: 16,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: vk.surfaceOverlay.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: vk.glassBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: List.generate(_navItems.length, (i) {
                      final item = _navItems[i];
                      final isSelected = _currentNavIndex == i;
                      final isDownloadTab = i == 2;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _currentNavIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.all(isSelected ? 6 : 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isDownloadTab)
                                  Badge(
                                    isLabelVisible: count > 0,
                                    label: Text(
                                      count > 99 ? '99+' : '$count',
                                      style: TextStyle(
                                        color: cs.surface,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: cs.primary,
                                    child: Icon(
                                      isSelected
                                          ? item.selectedIcon
                                          : item.icon,
                                      size: 22,
                                      color: isSelected
                                          ? cs.primary
                                          : vk.onSurfaceSubtle,
                                    ),
                                  )
                                else
                                  Icon(
                                    isSelected
                                        ? item.selectedIcon
                                        : item.icon,
                                    size: 22,
                                    color: isSelected
                                        ? cs.primary
                                        : vk.onSurfaceSubtle,
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? cs.primary
                                        : vk.onSurfaceSubtle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentScreen() {
    return IndexedStack(
      index: _currentNavIndex,
      children: [
        _buildHomeTab(),
        const WishlistScreen(),
        const DownloadsScreen(),
        const SettingsScreen(),
      ],
    );
  }

  Widget _buildHomeTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final horizontalPadding = isCompact ? 16.0 : 24.0;
        final searchBarHeight = isCompact ? 44.0 : 52.0;
        final iconSize = isCompact ? 20.0 : 24.0;
        final fontSize = isCompact ? 14.0 : 16.0;

        final brandCs = Theme.of(context).colorScheme;
        final brandVk = context.vivek;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                4,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WALLBIZZ',
                        style: GoogleFonts.oswald(
                          fontSize: isCompact ? 22 : 28,
                          fontWeight: FontWeight.bold,
                          color: brandCs.primary,
                          letterSpacing: 3,
                        ),
                      ),
                      Text(
                        'curated wallpapers',
                        style: GoogleFonts.inter(
                          fontSize: isCompact ? 11 : 13,
                          fontWeight: FontWeight.w500,
                          color: brandVk.onSurfaceSubtle,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                8,
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
                    color: context.vivek.surfaceOverlay,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 20),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: context.vivek.onSurfaceSubtle, size: iconSize),
                      SizedBox(width: isCompact ? 12 : 16),
                      Text(
                        'Search wallpapers...',
                        style: TextStyle(
                          color: context.vivek.onSurfaceSubtle,
                          fontSize: fontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            CategoryTabs(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() => _selectedCategory = category);
              },
            ),
            Expanded(
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
