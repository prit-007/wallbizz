import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/downloaded_wallpaper.dart';
import '../services/downloads_service.dart';
import '../widgets/local_wallpaper_card.dart';
import 'downloaded_detail_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search downloads...',
              hintStyle: GoogleFonts.inter(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
          ),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: Hive.box('downloads').listenable(),
            builder: (context, Box box, _) {
              final filteredItems =
                  DownloadsService.getDownloads(searchQuery: _searchQuery);

              if (filteredItems.isEmpty) {
                return _buildEmptyView();
              }

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900
                        ? 4
                        : constraints.maxWidth > 600
                            ? 3
                            : 2;

                    return MasonryGridView.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final data = filteredItems[index];
                        return _buildDownloadCard(data);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadCard(DownloadedWallpaper data) {
    return LocalWallpaperCard(
      wallpaper: data,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DownloadedDetailScreen(downloadedWallpaper: data),
          ),
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_for_offline_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.15),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 24),
          Text(
            'No downloads yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the download button on any wallpaper\nto save it for offline viewing.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
