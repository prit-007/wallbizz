// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/backend_config.dart';
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
import '../widgets/add_to_moodboard_sheet.dart';
import 'wallpaper_editor_screen.dart';

class DetailScreen extends StatefulWidget {
  final Wallpaper wallpaper;

  const DetailScreen({super.key, required this.wallpaper});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with SingleTickerProviderStateMixin {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  bool _isWishlisted = false;

  final TransformationController _transformController = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;

  Wallpaper get wallpaper => widget.wallpaper;

  @override
  void initState() {
    super.initState();
    _checkDownloadState();
    _checkWishlist();
    _animationController = AnimationController(
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
    if (!kIsWeb) setState(() => _isDownloaded = DownloadsService.isDownloaded(wallpaper.wallhavenId));
  }

  Future<void> _checkWishlist() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final inList = await SupabaseService.instance.isInWishlist(user.id, wallpaper.id);
      if (mounted) setState(() => _isWishlisted = inList);
    } catch (_) {}
  }

  void _onHeartTap() {
    HapticFeedback.mediumImpact();
    WallpaperActions.handleHeartTap(
      context,
      wallpaper,
      onComplete: () {
        setState(() => _isWishlisted = !_isWishlisted);
        SupabaseService.wishlistNotifier.value++;
      },
    );
  }

  void _handleDoubleTap(TapDownDetails details) {
    HapticFeedback.lightImpact();
    final currentMatrix = _transformController.value;
    if (_animationController.isAnimating) return;

    final isZoomed = currentMatrix.getMaxScaleOnAxis() > 1.1;

    if (isZoomed) {
      _zoomAnimation = Matrix4Tween(
        begin: currentMatrix,
        end: Matrix4.identity(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
    } else {
      final position = details.localPosition;
      final targetMatrix = Matrix4.identity()
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        ..scale(2.5);
      _zoomAnimation = Matrix4Tween(
        begin: currentMatrix,
        end: targetMatrix,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
    }
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final ambientColor = ColorUtils.hexToColor(wallpaper.primaryColor);

    return GestureHintOverlay(
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(ambientColor.withValues(alpha: 0.5), BlendMode.srcOver),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 1.5,
                height: MediaQuery.of(context).size.height * 1.5,
                child: Transform.translate(
                  offset: Offset(-MediaQuery.of(context).size.width * 0.25, -MediaQuery.of(context).size.height * 0.25),
                  child: NetworkImageWidget(imageUrl: wallpaper.urlFull, fit: BoxFit.cover),
                ),
              ),
            ),
          ).animate().fade(duration: 600.ms),

          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                stops: const [0.2, 1.0],
              ),
            ),
          ),

          GestureDetector(
            onDoubleTapDown: _handleDoubleTap,
            onVerticalDragUpdate: (details) {
              final scale = _transformController.value.getMaxScaleOnAxis();
              if (scale <= 1.1 && details.primaryDelta! > 10) {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
              }
            },
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 1.0,
              maxScale: 5.0,
              child: Center(
                child: Hero(
                  tag: wallpaper.id,
                  child: NetworkImageWidget(imageUrl: wallpaper.urlFull, fit: BoxFit.contain),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
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
          ).animate().fade(duration: 400.ms, delay: 200.ms).slideX(begin: -0.2, end: 0),

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FrostedCircleButton(
                  icon: _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: _isWishlisted ? Colors.redAccent : Colors.white,
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
          ).animate().fade(duration: 400.ms, delay: 200.ms).slideX(begin: 0.2, end: 0),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpecsCard(wallpaper: wallpaper),
                  const SizedBox(height: 24),

                  _GlassActionButton(
                    onPressed: _isDownloading ? null : () {
                      HapticFeedback.mediumImpact();
                      _downloadWallpaper(context);
                    },
                    isDownloading: _isDownloading,
                    isDownloaded: _isDownloaded,
                    label: _isDownloading ? 'DOWNLOADING...' : (_isDownloaded ? 'DOWNLOADED' : 'DOWNLOAD WALLPAPER'),
                    icon: _isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                    backgroundColor: _isDownloaded ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.2),
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
                      backgroundColor: ambientColor,
                      textColor: ambientColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    ),
                  ],
                ],
              ),
            ).animate().slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic).fade(duration: 500.ms),
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _downloadWallpaper(BuildContext context) async {
    if (_isDownloaded || _isDownloading) return;
    final imageUrl = kIsWeb ? BackendConfig.proxyImageUrl(wallpaper.urlFull) : wallpaper.urlFull;
    final progress = ValueNotifier<double>(0.0);
    final fileName = DownloadService.fileNameFromUrl(wallpaper.urlFull);
    setState(() => _isDownloading = true);
    showGlassmorphismProgress(context, progress);

    try {
      await DownloadService.downloadImage(imageUrl: imageUrl, fileName: fileName, onProgress: (p) => progress.value = p);
      if (!kIsWeb) await DownloadsService.downloadAndSave(wallpaper);
      if (context.mounted) {
        Navigator.of(context).pop();
        setState(() { _isDownloading = false; _isDownloaded = true; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Download complete!'), backgroundColor: Colors.black.withValues(alpha: 0.9)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  void showGlassmorphismProgress(BuildContext context, ValueNotifier<double> progress) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => PopScope(
        canPop: false,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: progress,
                    builder: (_, value, _) => SizedBox(
                      width: 80, height: 80,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: value > 0 ? value : null,
                            strokeWidth: 4,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(ColorUtils.hexToColor(wallpaper.primaryColor)),
                          ),
                          Center(
                            child: value > 0
                                ? Text('${(value * 100).toInt()}%', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                                : Icon(Icons.cloud_download_rounded, color: Colors.white.withValues(alpha: 0.8), size: 32),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 500.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutCubic),
                  const SizedBox(height: 24),
                  Text('DOWNLOADING', style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white))
                    .animate().fade(duration: 400.ms, delay: 100.ms).slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 4),
                  Text(wallpaper.resolution.replaceAll('x', ' \u00d7 '), style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)))
                    .animate().fade(duration: 400.ms, delay: 180.ms),
                ],
              ),
            ).animate().fade(duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutCubic),
          ),
        ),
      ),
    );
  }

  void _setWallpaper(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WallpaperEditorScreen(localPath: '', urlFull: wallpaper.urlFull, primaryColor: wallpaper.primaryColor, resolution: wallpaper.resolution, width: wallpaper.width, height: wallpaper.height),
    ));
  }

  void _shareWallpaper(BuildContext context) {
    ShareUtils.shareWithWatermark(
      imageUrl: wallpaper.urlFull,
      context: context,
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
      builder: (_) => AddToMoodboardSheet(wallpaperId: wallpaper.id),
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 20),
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
              color: widget.isDownloaded ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isDownloading)
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: widget.textColor))
              else
                Icon(widget.icon, color: widget.textColor, size: 20),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1, color: widget.textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
