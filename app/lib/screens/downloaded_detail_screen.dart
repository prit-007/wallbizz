import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../config/theme_config.dart';
import '../models/downloaded_wallpaper.dart';
import '../utils/color_utils.dart';
import '../widgets/dynamic_theme.dart';
import '../widgets/specs_card.dart';
import '../models/wallpaper.dart';
import 'wallpaper_editor_screen.dart';

class DownloadedDetailScreen extends StatelessWidget {
  final DownloadedWallpaper downloadedWallpaper;

  const DownloadedDetailScreen({super.key, required this.downloadedWallpaper});

  Wallpaper get _wallpaper => Wallpaper(
        id: 'wh-${downloadedWallpaper.wallhavenId}',
        wallhavenId: downloadedWallpaper.wallhavenId,
        urlFull: downloadedWallpaper.urlFull,
        urlThumb: downloadedWallpaper.urlThumb,
        resolution: downloadedWallpaper.resolution,
        width: downloadedWallpaper.width,
        height: downloadedWallpaper.height,
        fileSize: downloadedWallpaper.fileSize,
        primaryColor: downloadedWallpaper.primaryColor,
        category: downloadedWallpaper.category,
        sourceQuery: downloadedWallpaper.sourceQuery,
        createdAt: downloadedWallpaper.downloadedAt,
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final file = File(downloadedWallpaper.localPath);
    final hasLocalFile = file.existsSync();

    return Scaffold(
      backgroundColor: cs.surface,
      body: DynamicTheme(
        primaryColor: downloadedWallpaper.primaryColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            hasLocalFile
                ? Image.file(file, fit: BoxFit.contain)
                : Image.network(
                    downloadedWallpaper.urlFull,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: vk.surfaceContainer,
                        child: Center(
                          child: CircularProgressIndicator(color: vk.onSurfaceDim),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: vk.surfaceContainer,
                        child: Icon(Icons.error_outline, color: vk.onSurfaceDim),
                      );
                    },
                  ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: cs.onSurface,
                    size: 24,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _shareWallpaper(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.share,
                        color: cs.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: vk.glassBorder,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: vk.glassBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: cs.onSurface,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Downloaded',
                          style: GoogleFonts.inter(
                            color: cs.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpecsCard(wallpaper: _wallpaper),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _openEditor(context),
                        icon: const Icon(Icons.wallpaper),
                        label: Text(
                          'Set as Wallpaper',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              ColorUtils.hexToColor(downloadedWallpaper.primaryColor),
                          foregroundColor: cs.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.3, end: 0).fade(),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WallpaperEditorScreen(
          localPath: downloadedWallpaper.localPath,
          urlFull: downloadedWallpaper.urlFull,
          primaryColor: downloadedWallpaper.primaryColor,
          resolution: downloadedWallpaper.resolution,
          width: downloadedWallpaper.width,
          height: downloadedWallpaper.height,
        ),
      ),
    );
  }

  void _shareWallpaper(BuildContext context) {
    final file = File(downloadedWallpaper.localPath);
    if (file.existsSync()) {
      Share.shareXFiles(
        [XFile(downloadedWallpaper.localPath)],
        text: 'Check out this wallpaper from Vivek Wallpapers!',
      );
    } else {
      Share.share(
        'Check out this wallpaper from Vivek Wallpapers!\n${downloadedWallpaper.urlFull}',
        subject: 'Vivek Wallpapers',
      );
    }
  }
}
