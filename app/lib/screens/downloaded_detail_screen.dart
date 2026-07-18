import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
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
    final file = File(downloadedWallpaper.localPath);
    final hasLocalFile = file.existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      body: DynamicTheme(
        primaryColor: downloadedWallpaper.primaryColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            hasLocalFile
                ? Image.file(file, fit: BoxFit.cover)
                : Image.network(
                    downloadedWallpaper.urlFull,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white24),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.error_outline, color: Colors.white24),
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
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
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
                      child: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Downloaded',
                          style: GoogleFonts.inter(
                            color: Colors.white,
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
                          foregroundColor: Colors.white,
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
