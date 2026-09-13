// ignore_for_file: deprecated_member_use
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/backend_config.dart';
import '../config/responsive_config.dart';
import '../models/wallpaper.dart';
import '../services/download_service.dart';
import '../services/downloads_service.dart';
import '../services/supabase_service.dart';
import '../services/wallpaper_actions.dart';
import '../utils/color_utils.dart';
import '../utils/share_utils.dart';
import '../widgets/specs_card.dart';
import '../widgets/network_image.dart';
import '../widgets/gesture_hint_overlay.dart';
import '../widgets/hover_builder.dart';
import '../widgets/add_to_moodboard_sheet.dart';
import 'wallpaper_editor_screen.dart';

class WallpaperSwiperScreen extends StatefulWidget {
  final List<Wallpaper> wallpapers;
  final int initialIndex;

  const WallpaperSwiperScreen({
    super.key,
    required this.wallpapers,
    this.initialIndex = 0,
  });

  @override
  State<WallpaperSwiperScreen> createState() => _WallpaperSwiperScreenState();
}

class _WallpaperSwiperScreenState extends State<WallpaperSwiperScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isUiVisible = true;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  bool _isWishlisted = false;

  final TransformationController _transformController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;

  double _dragOffset = 0;
  double _dragStartY = 0;
  bool _isSwiping = false;

  Wallpaper get _currentWallpaper => widget.wallpapers[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _checkDownloadState();
    _checkWishlist();
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
    _pageController.dispose();
    _transformController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _checkDownloadState() {
    if (!kIsWeb) {
      setState(
        () => _isDownloaded = DownloadsService.isDownloaded(
          _currentWallpaper.wallhavenId,
        ),
      );
    }
  }

  Future<void> _checkWishlist() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final inList = await SupabaseService.instance.isInWishlist(
        user.id,
        _currentWallpaper.id,
      );
      if (mounted) setState(() => _isWishlisted = inList);
    } catch (_) {}
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isDownloaded = false;
      _isWishlisted = false;
    });
    _checkDownloadState();
    _checkWishlist();
    HapticFeedback.lightImpact();
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
      _dragOffset = dy.clamp(0.0, MediaQuery.of(context).size.height * 0.4);
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

  void _onHeartTap() {
    HapticFeedback.mediumImpact();
    WallpaperActions.handleHeartTap(
      context,
      _currentWallpaper,
      onToggle: () => setState(() => _isWishlisted = !_isWishlisted),
      onComplete: () => SupabaseService.wishlistNotifier.value++,
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = context.isDesktop;

    if (desktop) {
      return _buildDesktopLayout();
    }
    return _buildMobileLayout();
  }

  // ─── Desktop split-view layout ──────────────────────────────

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // Left: wallpaper viewer
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildAmbientBackground(),
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
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.wallpapers.length,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final wp = widget.wallpapers[index];
                      return GestureDetector(
                        onDoubleTapDown: _handleDoubleTap,
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          minScale: 1.0,
                          maxScale: 5.0,
                          panEnabled: false,
                          scaleEnabled: true,
                          child: Center(
                            child: Hero(
                              tag: wp.id,
                              child: NetworkImageWidget(
                                imageUrl: wp.urlFull,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  child: _FrostedCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                // Page counter
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.wallpapers.length}',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Page dots
                if (widget.wallpapers.length > 1)
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: _buildPageIndicator(),
                  ),
              ],
            ),
          ),

          // Divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),

          // Right: sidebar panel
          SizedBox(width: 380, child: _buildDesktopSidebar()),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: const Color(0xFF0E0E1C),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallpaper title / ID
              Text(
                wallpaper.sourceQuery.toUpperCase(),
                style: GoogleFonts.oswald(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ColorUtils.hexToColor(wallpaper.primaryColor),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${wallpaper.resolution.replaceAll('x', ' × ')} • ${wallpaper.formattedFileSize}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),

              // Specs card (no glassmorphism background on desktop)
              SpecsCard(wallpaper: _currentWallpaper),
              const SizedBox(height: 24),

              // Heart button
              _DesktopActionButton(
                icon: _isWishlisted
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: _isWishlisted ? 'WISHLISTED' : 'ADD TO WISHLIST',
                color: _isWishlisted ? Colors.redAccent : cs.primary,
                onTap: _onHeartTap,
              ),
              const SizedBox(height: 12),

              // Download button
              _DesktopActionButton(
                icon: _isDownloaded
                    ? Icons.check_circle_rounded
                    : Icons.download_rounded,
                label: _isDownloading
                    ? 'DOWNLOADING...'
                    : (_isDownloaded ? 'DOWNLOADED' : 'DOWNLOAD'),
                color: cs.primary,
                isLoading: _isDownloading,
                onTap: _isDownloading
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        _downloadWallpaper(context);
                      },
              ),
              const SizedBox(height: 12),

              // Set as wallpaper (not on web)
              if (!kIsWeb)
                _DesktopActionButton(
                  icon: Icons.wallpaper_rounded,
                  label: 'SET AS WALLPAPER',
                  color: ColorUtils.hexToColor(_currentWallpaper.primaryColor),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _setWallpaper(context);
                  },
                ),
              if (!kIsWeb) const SizedBox(height: 12),

              // Moodboard
              _DesktopActionButton(
                icon: Icons.dashboard_customize_rounded,
                label: 'ADD TO MOODBOARD',
                color: cs.tertiary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showMoodboardSheet(context);
                },
              ),
              const SizedBox(height: 12),

              // Share
              _DesktopActionButton(
                icon: Icons.ios_share_rounded,
                label: 'SHARE',
                color: cs.secondary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _shareWallpaper(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Wallpaper get wallpaper => _currentWallpaper;

  // ─── Mobile layout (existing) ───────────────────────────────

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        child: GestureHintOverlay(
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildAmbientBackground(),

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

                Positioned.fill(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.wallpapers.length,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final wp = widget.wallpapers[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _isUiVisible = !_isUiVisible);
                          HapticFeedback.selectionClick();
                        },
                        onDoubleTapDown: _handleDoubleTap,
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          minScale: 1.0,
                          maxScale: 5.0,
                          panEnabled: false,
                          scaleEnabled: true,
                          child: Center(
                            child: Hero(
                              tag: wp.id,
                              child: NetworkImageWidget(
                                imageUrl: wp.urlFull,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom gradient
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
                              ColorUtils.hexToColor(
                                _currentWallpaper.primaryColor,
                              ).withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.95),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Top buttons
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
                            icon: Icons.arrow_back_ios_new_rounded,
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Text(
                                  '${_currentIndex + 1} / ${widget.wallpapers.length}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _FrostedCircleButton(
                                icon: _isWishlisted
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                iconColor: _isWishlisted
                                    ? Colors.redAccent
                                    : Colors.white,
                                onTap: _onHeartTap,
                              ),
                              const SizedBox(width: 12),
                              _FrostedCircleButton(
                                icon: Icons.dashboard_customize_rounded,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _showMoodboardSheet(context);
                                },
                              ),
                              const SizedBox(width: 12),
                              _FrostedCircleButton(
                                icon: Icons.ios_share_rounded,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _shareWallpaper(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom panel
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
                            SpecsCard(wallpaper: _currentWallpaper),
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
                                  ? Icons.check_circle_rounded
                                  : Icons.download_rounded,
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
                                icon: Icons.wallpaper_rounded,
                                backgroundColor: ColorUtils.hexToColor(
                                  _currentWallpaper.primaryColor,
                                ),
                                textColor:
                                    ColorUtils.hexToColor(
                                          _currentWallpaper.primaryColor,
                                        ).computeLuminance() >
                                        0.5
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

                if (widget.wallpapers.length > 1)
                  Positioned(
                    bottom:
                        MediaQuery.of(context).padding.bottom +
                        (kIsWeb ? 180 : 230),
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isUiVisible ? 1.0 : 0.0,
                      child: _buildPageIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientBackground() {
    final ambientColor = ColorUtils.hexToColor(_currentWallpaper.primaryColor);
    return Positioned.fill(
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
                  imageUrl: _currentWallpaper.urlFull,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ).animate().fade(duration: 600.ms),
    );
  }

  Widget _buildPageIndicator() {
    final total = widget.wallpapers.length;
    const maxDots = 7;
    final start = max(0, _currentIndex - (maxDots ~/ 2));
    final end = min(total, start + maxDots);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(end - start, (i) {
        final index = start + i;
        final isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Future<void> _downloadWallpaper(BuildContext context) async {
    if (_isDownloaded || _isDownloading) return;
    final imageUrl = kIsWeb
        ? BackendConfig.proxyImageUrl(_currentWallpaper.urlFull)
        : _currentWallpaper.urlFull;
    final progress = ValueNotifier<double>(0.0);
    final fileName = DownloadService.fileNameFromUrl(_currentWallpaper.urlFull);
    setState(() => _isDownloading = true);

    if (context.isDesktop) {
      _showDesktopDownloadProgress(progress);
    } else {
      _showGlassmorphismProgress(context, progress);
    }

    try {
      await DownloadService.downloadImage(
        imageUrl: imageUrl,
        fileName: fileName,
        onProgress: (p) => progress.value = p,
      );
      if (!kIsWeb) await DownloadsService.downloadAndSave(_currentWallpaper);
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

  void _showDesktopDownloadProgress(ValueNotifier<double> progress) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(32),
              width: 300,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ColorUtils.hexToColor(
                                _currentWallpaper.primaryColor,
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
                                      decoration: TextDecoration.none,
                                    ),
                                  )
                                : Icon(
                                    Icons.cloud_download_rounded,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 32,
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
                      color: Colors.white,
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
  }

  void _showGlassmorphismProgress(
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
                                                _currentWallpaper.primaryColor,
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
                                            : Icon(
                                                Icons.cloud_download_rounded,
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
                            _currentWallpaper.resolution.replaceAll(
                              'x',
                              ' \u00d7 ',
                            ),
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
          urlFull: _currentWallpaper.urlFull,
          primaryColor: _currentWallpaper.primaryColor,
          resolution: _currentWallpaper.resolution,
          width: _currentWallpaper.width,
          height: _currentWallpaper.height,
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
        ? BackendConfig.proxyImageUrl(_currentWallpaper.urlFull)
        : _currentWallpaper.urlFull;
    await ShareUtils.shareWithWatermark(imageUrl: shareUrl, context: context);
    if (context.mounted) Navigator.of(context).pop();
  }

  void _showMoodboardSheet(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      WallpaperActions.handleHeartTap(context, _currentWallpaper);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddToMoodboardSheet(wallpaperId: _currentWallpaper.id),
    );
  }
}

class _FrostedCircleButton extends StatefulWidget {
  final IconData icon;
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
              child: Icon(widget.icon, color: widget.iconColor, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _DesktopActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      builder: (context, isHovered) {
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isHovered
                  ? color.withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isHovered
                    ? color.withValues(alpha: 0.4)
                    : color.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                else
                  Icon(icon, color: color, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: color,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlassActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isDownloading;
  final bool isDownloaded;
  final String label;
  final IconData icon;
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
                Icon(widget.icon, color: widget.textColor, size: 20),
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
