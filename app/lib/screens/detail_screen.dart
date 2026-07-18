import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../config/backend_config.dart';
import '../config/theme_config.dart';
import '../models/wallpaper.dart';
import '../services/download_service.dart';
import '../services/downloads_service.dart';
import '../utils/color_utils.dart';
import '../widgets/dynamic_theme.dart';
import '../widgets/specs_card.dart';
import '../widgets/network_image.dart';
import 'wallpaper_editor_screen.dart';

class DetailScreen extends StatefulWidget {
  final Wallpaper wallpaper;

  const DetailScreen({super.key, required this.wallpaper});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isDownloading = false;
  bool _isDownloaded = false;

  Wallpaper get wallpaper => widget.wallpaper;

  @override
  void initState() {
    super.initState();
    _checkDownloadState();
  }

  void _checkDownloadState() {
    if (!kIsWeb) {
      setState(() {
        _isDownloaded = DownloadsService.isDownloaded(wallpaper.wallhavenId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    return Scaffold(
      body: DynamicTheme(
        primaryColor: wallpaper.primaryColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkImageWidget(
              imageUrl: wallpaper.urlFull,
              fit: BoxFit.contain,
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
              child: GestureDetector(
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
                    size: 24,
                  ),
                ),
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
                    SpecsCard(wallpaper: wallpaper),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading
                            ? null
                            : () => _downloadWallpaper(context),
                        icon: _isDownloading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onSurface,
                                ),
                              )
                            : Icon(
                                _isDownloaded
                                    ? Icons.check_circle
                                    : Icons.download,
                              ),
                        label: Text(
                          _isDownloading
                              ? 'Downloading...'
                              : _isDownloaded
                                  ? 'Downloaded'
                                  : 'Download Wallpaper',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDownloaded
                              ? vk.glassBackground
                              : ColorUtils.hexToColor(wallpaper.primaryColor),
                          foregroundColor: cs.onSurface,
                          disabledBackgroundColor: vk.surfaceOverlay,
                          disabledForegroundColor: vk.onSurfaceSubtle,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (!kIsWeb) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => _setWallpaper(context),
                          icon: const Icon(Icons.wallpaper),
                          label: Text(
                            'Set as Wallpaper',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.onSurface,
                            side: BorderSide(color: vk.glassBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().slideY(begin: 0.3, end: 0).fade(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadWallpaper(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;

    if (_isDownloaded || _isDownloading) return;

    final imageUrl = kIsWeb
        ? BackendConfig.proxyImageUrl(wallpaper.urlFull)
        : wallpaper.urlFull;

    final progress = ValueNotifier<double>(0.0);
    final fileName = DownloadService.fileNameFromUrl(wallpaper.urlFull);

    setState(() => _isDownloading = true);

    showGlassmorphismProgress(context, progress);

    try {
      await DownloadService.downloadImage(
        imageUrl: imageUrl,
        fileName: fileName,
        onProgress: (p) => progress.value = p,
      );

      if (!kIsWeb) {
        await DownloadsService.downloadAndSave(wallpaper);
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Download complete!'),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: cs.onSurface,
              onPressed: () {
                // Navigate to downloads tab
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  void showGlassmorphismProgress(
    BuildContext context,
    ValueNotifier<double> progress,
  ) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: vk.glassBorder,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<double>(
                        valueListenable: progress,
                        builder: (_, value, _) => SizedBox(
                          width: 64,
                          height: 64,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: value > 0 ? value : null,
                                strokeWidth: 4,
                                backgroundColor: vk.glassBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ColorUtils.hexToColor(wallpaper.primaryColor),
                                ),
                              ),
                              Center(
                                child: value > 0
                                    ? Text(
                                        '${(value * 100).toInt()}%',
                                        style: GoogleFonts.inter(
                                          color: cs.onSurface,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : Icon(
                                        Icons.download,
                                        color: cs.onSurface.withValues(alpha: 0.7),
                                        size: 24,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'DOWNLOADING',
                        style: GoogleFonts.oswald(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        wallpaper.resolution.replaceAll('x', ' × '),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: vk.onSurfaceSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setWallpaper(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WallpaperEditorScreen(
          localPath: '',
          urlFull: wallpaper.urlFull,
          primaryColor: wallpaper.primaryColor,
          resolution: wallpaper.resolution,
          width: wallpaper.width,
          height: wallpaper.height,
        ),
      ),
    );
  }

  void _shareWallpaper(BuildContext context) {
    Share.share(
      'Check out this wallpaper from Vivek Wallpapers!\n${wallpaper.urlFull}',
      subject: 'Vivek Wallpapers',
    );
  }
}
