import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme_config.dart';
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
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = Theme.of(ctx).colorScheme;
        final v = ctx.vivek;
        return AlertDialog(
          title: Text(
            'Delete ${_selectedIds.length} wallpaper${_selectedIds.length == 1 ? '' : 's'}?',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: c.onSurface,
            ),
          ),
          content: Text(
            'This will permanently delete the selected wallpaper${_selectedIds.length == 1 ? '' : 's'} from your device.',
            style: GoogleFonts.inter(color: v.onSurfaceSubtle),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.inter()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(color: c.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    for (final id in _selectedIds.toList()) {
      await DownloadsService.removeDownload(id);
    }

    if (!mounted) return;

    _exitSelectionMode();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${_selectedIds.length} wallpaper${_selectedIds.length == 1 ? '' : 's'}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    return Column(
      children: [
        if (_selectionMode)
          Container(
            padding: EdgeInsets.fromLTRB(
              4,
              MediaQuery.of(context).padding.top + 4,
              4,
              4,
            ),
            color: cs.surfaceContainerHighest,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectionMode,
                  color: cs.onSurface,
                ),
                Expanded(
                  child: Text(
                    '${_selectedIds.length} selected',
                    style: GoogleFonts.inter(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
                  color: _selectedIds.isNotEmpty ? cs.error : vk.onSurfaceFaint,
                ),
              ],
            ),
          ),
        if (!_selectionMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              style: GoogleFonts.inter(color: cs.onSurface, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search downloads...',
                hintStyle: GoogleFonts.inter(color: vk.onSurfaceSubtle),
                prefixIcon: Icon(Icons.search, color: vk.onSurfaceSubtle),
                filled: true,
                fillColor: vk.surfaceOverlay,
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
    if (_selectionMode) {
      return LocalWallpaperCard(
        wallpaper: data,
        isSelected: _selectedIds.contains(data.wallhavenId),
        onTap: () => _toggleSelection(data.wallhavenId),
      );
    }

    return LocalWallpaperCard(
      wallpaper: data,
      isSelected: false,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DownloadedDetailScreen(downloadedWallpaper: data),
          ),
        );
      },
      onLongPress: () => _enterSelectionMode(data.wallhavenId),
    );
  }

  Widget _buildEmptyView() {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_for_offline_outlined,
            size: 80,
            color: vk.glassBackground,
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
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the download button on any wallpaper\nto save it for offline viewing.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: vk.onSurfaceSubtle,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
