// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme_config.dart';
import '../models/downloaded_wallpaper.dart';
import '../utils/color_utils.dart';
import '../utils/share_utils.dart';
import '../widgets/dynamic_theme.dart';
import '../widgets/specs_card.dart';
import '../models/wallpaper.dart';
import 'wallpaper_editor_screen.dart';

class DownloadedDetailScreen extends StatefulWidget {
  final DownloadedWallpaper downloadedWallpaper;

  const DownloadedDetailScreen({super.key, required this.downloadedWallpaper});

  @override
  State<DownloadedDetailScreen> createState() => _DownloadedDetailScreenState();
}

class _DownloadedDetailScreenState extends State<DownloadedDetailScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;

  DownloadedWallpaper get downloadedWallpaper => widget.downloadedWallpaper;

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
  void initState() {
    super.initState();
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addListener(() {
          if (_zoomAnimation != null) {
            _transformController.value = _zoomAnimation!.value;
          }
        });
  }

  @override
  void dispose() {
    _transformController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    HapticFeedback.lightImpact();
    final currentMatrix = _transformController.value;
    if (_animationController.isAnimating) return;

    final isZoomed = currentMatrix.getMaxScaleOnAxis() > 1.1;

    if (isZoomed) {
      _zoomAnimation =
          Matrix4Tween(begin: currentMatrix, end: Matrix4.identity()).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            ),
          );
    } else {
      final position = details.localPosition;
      final targetMatrix = Matrix4.identity()
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        ..scale(2.5);
      _zoomAnimation = Matrix4Tween(begin: currentMatrix, end: targetMatrix)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            ),
          );
    }
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final file = File(downloadedWallpaper.localPath);
    late final bool hasLocalFile;
    try {
      hasLocalFile = file.existsSync();
    } catch (_) {
      hasLocalFile = false;
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: DynamicTheme(
        primaryColor: downloadedWallpaper.primaryColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onDoubleTapDown: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 1.0,
                maxScale: 5.0,
                panEnabled: true,
                scaleEnabled: true,
                child: Center(
                  child: hasLocalFile
                      ? Image.file(file, fit: BoxFit.contain)
                      : Image.network(
                          downloadedWallpaper.urlFull,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: vk.surfaceContainer,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: vk.onSurfaceDim,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: vk.surfaceContainer,
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedAlertCircle,
                                color: vk.onSurfaceDim,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),

            // Bottom Gradient Overlay (Wrapped in IgnorePointer to fix pinch-to-zoom block)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
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
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
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
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedShare01,
                        color: cs.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: vk.glassBorder,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: vk.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
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
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedImage01,
                        ),
                        label: Text(
                          'Set as Wallpaper',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorUtils.hexToColor(
                            downloadedWallpaper.primaryColor,
                          ),
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

  Future<void> _shareWallpaper(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    'Preparing share...',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final file = File(downloadedWallpaper.localPath);
    Uint8List? bytes;
    if (file.existsSync()) {
      bytes = await file.readAsBytes();
    }
    if (!context.mounted) return;
    await ShareUtils.shareWithWatermark(
      imageUrl: downloadedWallpaper.urlFull,
      context: context,
      imageBytes: bytes,
    );
    if (context.mounted) Navigator.of(context).pop();
  }
}
