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
          return NavigationBar(
            selectedIndex: _currentNavIndex,
            onDestinationSelected: (index) {
              setState(() => _currentNavIndex = index);
            },
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.grid_view, color: vk.onSurfaceSubtle),
                selectedIcon: Icon(Icons.grid_view, color: cs.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border, color: vk.onSurfaceSubtle),
                selectedIcon: Icon(Icons.favorite, color: cs.primary),
                label: 'My Collection',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text(
                    count > 99 ? '99+' : '$count',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: cs.primary,
                  child: Icon(Icons.download_outlined, color: vk.onSurfaceSubtle),
                ),
                selectedIcon: Badge(
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
                  child: Icon(Icons.download, color: cs.onSurface),
                ),
                label: 'Downloads',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined, color: vk.onSurfaceSubtle),
                selectedIcon: Icon(Icons.settings, color: cs.primary),
                label: 'Settings',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentNavIndex) {
      case 0:
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
}
