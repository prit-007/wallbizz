// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/backend_config.dart';
import '../core/logger/logger.dart';
import '../models/wallpaper.dart';
import '../services/download_service.dart';
import '../services/downloads_service.dart';
import '../services/hive_wishlist_service.dart';
import '../services/wallpaper_actions.dart';
import '../utils/color_utils.dart';
import '../utils/share_utils.dart';
import '../widgets/specs_card.dart';
import '../widgets/network_image.dart';
import '../widgets/gesture_hint_overlay.dart';
import '../widgets/add_to_moodboard_sheet.dart';
import 'wallpaper_editor_screen.dart';

class DetailScreen extends StatefulWidget {
  final Wallpaper wallpaper;

  const DetailScreen({super.key, required this.wallpaper});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  bool _isWishlisted = false;
  bool _isUiVisible = true;

  final TransformationController _transformController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;

  double _dragOffset = 0;
  double _dragStartY = 0;
  bool _isSwiping = false;

  Wallpaper get wallpaper => widget.wallpaper;

  void _precacheImage() {
    final url = kIsWeb
        ? BackendConfig.proxyImageUrl(wallpaper.urlFull)
        : wallpaper.urlFull;
    precacheImage(NetworkImage(url), context).catchError((_) {});
  }

  @override
  void initState() {
    super.initState();
    logInfo(
      'Detail screen opened: ${wallpaper.wallhavenId}',
      domain: LogDomain.image,
    );
    _checkDownloadState();
    _checkWishlist();
    _precacheImage();
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

  void _checkDownloadState() {
    if (!kIsWeb) {
      setState(
        () => _isDownloaded = DownloadsService.isDownloaded(
          wallpaper.wallhavenId,
        ),
      );
    }
  }

  Future<void> _checkWishlist() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id ?? 'anonymous';
      final inList = await HiveWishlistService.isWishlisted(
        userId,
        wallpaper.wallhavenId,
      );
      if (mounted) setState(() => _isWishlisted = inList);
    } catch (_) {}
  }

  void _onHeartTap() {
    HapticFeedback.mediumImpact();
    WallpaperActions.handleHeartTap(
      context,
      wallpaper,
      onToggle: () => setState(() => _isWishlisted = !_isWishlisted),
      onComplete: () => HiveWishlistService.wishlistNotifier.value++,
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_transformController.value.getMaxScaleOnAxis() > 1.1) return;
    _dragStartY = event.position.dy;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_transformController.value.getMaxScaleOnAxis() > 1.1) {
      _dragOffset = 0;
      _isSwiping = false;
      return;
    }
    final dy = event.position.dy - _dragStartY;
    if (dy > 10) _isSwiping = true;
    if (!_isSwiping) return;
    setState(() {
      _dragOffset = dy.clamp(0, MediaQuery.of(context).size.height * 0.4);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isSwiping) return;
    _isSwiping = false;
    final threshold = MediaQuery.of(context).size.height * 0.25;
    if (_dragOffset > threshold) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0);
    }
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
    final ambientColor = ColorUtils.hexToColor(wallpaper.primaryColor);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
            return KeyEventResult.ignored;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.browserBack) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          child: GestureHintOverlay(
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Ambient Blur Background Layer
                  Positioned.fill(
                    child: ClipRect(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            ambientColor.withValues(alpha: 0.5),
                            BlendMode.srcOver,
                          ),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 1.5,
                            height: MediaQuery.of(context).size.height * 1.5,
                            child: Transform.translate(
                              offset: Offset(
                                -MediaQuery.of(context).size.width * 0.25,
                                -MediaQuery.of(context).size.height * 0.25,
                              ),
                              child: NetworkImageWidget(
                                imageUrl: wallpaper.urlFull,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ).animate().fade(duration: 600.ms),
                  ),

                  // 2. Base Radial Darkening Gradient
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.0,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                            stops: const [0.2, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Core Interactive Viewer Layer + Single Tap to Toggle UI
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isUiVisible = !_isUiVisible);
                        HapticFeedback.selectionClick();
                      },
                      onDoubleTapDown: _handleDoubleTap,
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        minScale: 1.0,
                        maxScale: 5.0,
                        panEnabled: true,
                        scaleEnabled: true,
                        child: Center(
                          child: Hero(
                            tag: wallpaper.id,
                            child: NetworkImageWidget(
                              imageUrl: wallpaper.urlFull,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. Bottom Gradient Overlay (Fades out when UI is hidden)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isUiVisible ? 1.0 : 0.0,
                      child: IgnorePointer(
                        child: Container(
                          height: 450,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                ambientColor.withValues(alpha: 0.2),
                                Colors.black.withValues(alpha: 0.95),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 5. Top Action Buttons (Slides up and fades out)
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    offset: _isUiVisible ? Offset.zero : const Offset(0, -1.5),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: _isUiVisible ? 1.0 : 0.0,
                      child: Stack(
                        children: [
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 12,
                            left: 16,
                            child: _FrostedCircleButton(
                              icon: HugeIcons.strokeRoundedArrowLeft01,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 12,
                            right: 16,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _FrostedCircleButton(
                                  icon: _isWishlisted
                                      ? HugeIcons.strokeRoundedFavourite
                                      : HugeIcons.strokeRoundedFavourite,
                                  iconColor: _isWishlisted
                                      ? Colors.redAccent
                                      : Colors.white,
                                  onTap: _onHeartTap,
                                ),
                                const SizedBox(width: 12),
                                _FrostedCircleButton(
                                  icon: HugeIcons.strokeRoundedGridView,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _showMoodboardSheet(context);
                                  },
                                ),
                                const SizedBox(width: 12),
                                _FrostedCircleButton(
                                  icon: HugeIcons.strokeRoundedShare01,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _shareWallpaper(context);
                                  },
                                ),
                                const SizedBox(width: 12),
                                PopupMenuButton<String>(
                                  icon: ClipOval(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 12,
                                        sigmaY: 12,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: const HugeIcon(
                                          icon:
                                              HugeIcons.strokeRoundedSettings01,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  color: Colors.black.withValues(alpha: 0.85),
                                  onSelected: (value) {
                                    HapticFeedback.lightImpact();
                                    if (value == 'copy_url') {
                                      _copyUrl(context);
                                    } else if (value == 'report') {
                                      _reportWallpaper(context);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'copy_url',
                                      child: Row(
                                        children: [
                                          HugeIcon(
                                            icon: HugeIcons.strokeRoundedCopy01,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Copy URL',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'report',
                                      child: Row(
                                        children: [
                                          HugeIcon(
                                            icon:
                                                HugeIcons.strokeRoundedAlert01,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Report',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 6. Bottom Action Panel & Specs (Slides down and fades out)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      offset: _isUiVisible ? Offset.zero : const Offset(0, 1.5),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _isUiVisible ? 1.0 : 0.0,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            24,
                            24,
                            MediaQuery.of(context).padding.bottom + 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SpecsCard(wallpaper: wallpaper),
                              const SizedBox(height: 24),

                              _GlassActionButton(
                                onPressed: _isDownloading
                                    ? null
                                    : () {
                                        HapticFeedback.mediumImpact();
                                        _downloadWallpaper(context);
                                      },
                                isDownloading: _isDownloading,
                                isDownloaded: _isDownloaded,
                                label: _isDownloading
                                    ? 'DOWNLOADING...'
                                    : (_isDownloaded
                                          ? 'DOWNLOADED'
                                          : 'DOWNLOAD WALLPAPER'),
                                icon: _isDownloaded
                                    ? HugeIcons.strokeRoundedCheckmarkCircle01
                                    : HugeIcons.strokeRoundedDownload01,
                                backgroundColor: _isDownloaded
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.2),
                                textColor: Colors.white,
                              ),

                              if (!kIsWeb) ...[
                                const SizedBox(height: 12),
                                _GlassActionButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _setWallpaper(context);
                                  },
                                  isDownloading: false,
                                  isDownloaded: false,
                                  label: 'SET AS WALLPAPER',
                                  icon: HugeIcons.strokeRoundedImage01,
                                  backgroundColor: ambientColor,
                                  textColor:
                                      ambientColor.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadWallpaper(BuildContext context) async {
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
      if (!kIsWeb) await DownloadsService.downloadAndSave(wallpaper);
      if (context.mounted) {
        Navigator.of(context).pop();
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Download complete!'),
            backgroundColor: Colors.black.withValues(alpha: 0.9),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  void showGlassmorphismProgress(
    BuildContext context,
    ValueNotifier<double> progress,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child:
              Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ValueListenableBuilder<double>(
                                valueListenable: progress,
                                builder: (_, value, _) => SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CircularProgressIndicator(
                                        value: value > 0 ? value : null,
                                        strokeWidth: 4,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.1),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              ColorUtils.hexToColor(
                                                wallpaper.primaryColor,
                                              ),
                                            ),
                                      ),
                                      Center(
                                        child: value > 0
                                            ? Text(
                                                '${(value * 100).toInt()}%',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  decoration:
                                                      TextDecoration.none,
                                                ),
                                              )
                                            : HugeIcon(
                                                icon: HugeIcons
                                                    .strokeRoundedCloudDownload,
                                                color: Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                                size: 32,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .animate()
                              .fade(duration: 500.ms)
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1, 1),
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 24),
                          Text(
                                'DOWNLOADING',
                                style: GoogleFonts.oswald(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                  decoration: TextDecoration.none,
                                ),
                              )
                              .animate()
                              .fade(duration: 400.ms, delay: 100.ms)
                              .slideY(begin: 0.3, end: 0),
                          const SizedBox(height: 4),
                          Text(
                            wallpaper.resolution.replaceAll('x', ' \u00d7 '),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.6),
                              decoration: TextDecoration.none,
                            ),
                          ).animate().fade(duration: 400.ms, delay: 180.ms),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fade(duration: 300.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutCubic,
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
    final shareUrl = kIsWeb
        ? BackendConfig.proxyImageUrl(wallpaper.urlFull)
        : wallpaper.urlFull;
    await ShareUtils.shareWithWatermark(imageUrl: shareUrl, context: context);
    if (context.mounted) Navigator.of(context).pop();
  }

  void _copyUrl(BuildContext context) {
    final url = wallpaper.urlFull;
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('URL copied to clipboard'),
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _reportWallpaper(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Wallpaper'),
        content: const Text(
          'This will flag the wallpaper for review. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Wallpaper reported. Thank you!'),
                  backgroundColor: Colors.black.withValues(alpha: 0.9),
                ),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showMoodboardSheet(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      WallpaperActions.handleHeartTap(context, wallpaper);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddToMoodboardSheet(wallpaper: wallpaper),
    );
  }
}

class _FrostedCircleButton extends StatefulWidget {
  final dynamic icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _FrostedCircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  State<_FrostedCircleButton> createState() => _FrostedCircleButtonState();
}

class _FrostedCircleButtonState extends State<_FrostedCircleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: HugeIcon(
                icon: widget.icon,
                color: widget.iconColor,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isDownloading;
  final bool isDownloaded;
  final String label;
  final dynamic icon;
  final Color backgroundColor;
  final Color textColor;

  const _GlassActionButton({
    required this.onPressed,
    required this.isDownloading,
    required this.isDownloaded,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  State<_GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<_GlassActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDownloaded
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isDownloading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.textColor,
                  ),
                )
              else
                HugeIcon(icon: widget.icon, color: widget.textColor, size: 20),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: widget.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
