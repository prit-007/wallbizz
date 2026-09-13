import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/responsive_config.dart';
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
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<DownloadedWallpaper> items) {
    setState(() {
      if (_selectedIds.length == items.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds.addAll(items.map((e) => e.wallhavenId));
      }
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  String _storageSizeStr = '0 KB';

  @override
  void initState() {
    super.initState();
    _recalculateStorage();
  }

  void _recalculateStorage() {
    final all = DownloadsService.getDownloads();
    int totalBytes = 0;
    for (var item in all) {
      final file = File(item.localPath);
      try {
        if (file.existsSync()) {
          totalBytes += file.lengthSync();
        }
      } catch (_) {}
    }
    if (totalBytes < 1024 * 1024) {
      _storageSizeStr = '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      _storageSizeStr = '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = Theme.of(ctx).colorScheme;
        final v = ctx.vivek;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: v.surfaceContainerHigh.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: v.glassBorder.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                          icon: HugeIcons.strokeRoundedDelete03,
                          size: 48,
                          color: c.error.withValues(alpha: 0.9),
                        )
                        .animate()
                        .fade(duration: 400.ms)
                        .scale(
                          begin: const Offset(0.6, 0.6),
                          end: const Offset(1, 1),
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(height: 16),
                    Text(
                          'DELETE ${_selectedIds.length} ITEM${_selectedIds.length == 1 ? '' : 'S'}?',
                          style: GoogleFonts.oswald(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        )
                        .animate()
                        .fade(duration: 400.ms, delay: 100.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 12),
                    Text(
                          'This action will permanently remove the selected wallpaper${_selectedIds.length == 1 ? '' : 's'} from your device storage.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        )
                        .animate()
                        .fade(duration: 400.ms, delay: 180.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: v.glassBorder.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'CANCEL',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: c.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'DELETE',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fade(duration: 400.ms, delay: 260.ms),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    for (final id in _selectedIds.toList()) {
      await DownloadsService.removeDownload(id);
    }
    if (!mounted) return;
    final deletedCount = _selectedIds.length;
    _exitSelectionMode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted $deletedCount wallpaper${deletedCount == 1 ? '' : 's'}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 85;

    return ValueListenableBuilder(
      valueListenable: Hive.box('downloads').listenable(),
      builder: (context, Box box, _) {
        final filteredItems = DownloadsService.getDownloads(
          searchQuery: _searchQuery,
        );
        if (_storageSizeStr == '0 KB') _recalculateStorage();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_selectionMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VAULT',
                          style: GoogleFonts.oswald(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                            letterSpacing: 4,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(width: 40, height: 3, color: cs.primary),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: vk.surfaceContainer,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: vk.glassBorder, width: 1),
                      ),
                      child: Text(
                        '${filteredItems.length} ITEMS · $_storageSizeStr',
                        style: GoogleFonts.oswald(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface.withValues(alpha: 0.8),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_selectionMode)
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 8,
                  16,
                  12,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  border: Border(
                    bottom: BorderSide(
                      color: cs.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _exitSelectionMode,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${_selectedIds.length} SELECTED',
                        style: GoogleFonts.oswald(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _selectAll(filteredItems),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedIds.length == filteredItems.length
                              ? 'DESELECT ALL'
                              : 'SELECT ALL',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _selectedIds.isNotEmpty ? _deleteSelected : null,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _selectedIds.isNotEmpty
                              ? cs.error.withValues(alpha: 0.8)
                              : Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedDelete02,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(
                begin: -1.0,
                end: 0,
                duration: 250.ms,
                curve: Curves.easeOutCubic,
              ),

            if (!_selectionMode && box.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: vk.surfaceContainer,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: vk.glassBorder.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        color: vk.onSurfaceSubtle,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Search downloads by tags or resolution...',
                            hintStyle: GoogleFonts.inter(
                              color: vk.onSurfaceFaint,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) => setState(
                            () => _searchQuery = value.toLowerCase(),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _searchQuery = ''),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                            color: vk.onSurfaceFaint,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

                    Expanded(
                      child: filteredItems.isEmpty
                          ? _buildEmptyView()
                          : RefreshIndicator(
                              onRefresh: () async {
                                _recalculateStorage();
                                setState(() {});
                              },
                      color: cs.primary,
                      backgroundColor: cs.surface,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = context.gridColumns;

                          return MasonryGridView.count(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            padding: EdgeInsets.fromLTRB(
                              16,
                              8,
                              16,
                              bottomPadding,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final data = filteredItems[index];
                              return _buildDownloadCard(data)
                                  .animate()
                                  .fade(duration: 350.ms)
                                  .slideY(
                                    begin: 0.1,
                                    end: 0,
                                    delay: Duration(
                                      milliseconds:
                                          (index % crossAxisCount) * 40,
                                    ),
                                  );
                            },
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
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DownloadedDetailScreen(downloadedWallpaper: data),
        ),
      ),
      onLongPress: () => _enterSelectionMode(data.wallhavenId),
    );
  }

  Widget _buildEmptyView() {
    final vk = context.vivek;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: vk.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedDownload04,
                    size: 48,
                    color: vk.onSurfaceDim,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.1, duration: 1500.ms, curve: Curves.easeInOut),
            const SizedBox(height: 24),
            Text(
              'NO DOWNLOADS YET',
              style: GoogleFonts.oswald(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the download button on any wallpaper to save it for offline viewing in full resolution.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: vk.onSurfaceSubtle,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
