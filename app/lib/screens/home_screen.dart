import 'package:flutter/material.dart';
import '../widgets/category_tabs.dart';
import '../widgets/staggered_grid.dart';
import 'detail_screen.dart';
import 'search_screen.dart';
import 'wishlist_screen.dart';
import 'settings_screen.dart';

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) {
          setState(() => _currentNavIndex = index);
        },
        backgroundColor: Colors.black,
        indicatorColor: Colors.white.withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view, color: Colors.white54),
            selectedIcon: Icon(Icons.grid_view, color: Colors.white),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border, color: Colors.white54),
            selectedIcon: Icon(Icons.favorite, color: Colors.white),
            label: 'My Collection',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.settings, color: Colors.white),
            label: 'Settings',
          ),
        ],
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

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
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
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 20),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.white54, size: iconSize),
                          SizedBox(width: isCompact ? 12 : 16),
                          Text(
                            'Search wallpapers...',
                            style: TextStyle(
                              color: Colors.white54,
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
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}
