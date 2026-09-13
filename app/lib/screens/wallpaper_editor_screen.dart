// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/color_utils.dart';

class WallpaperEditorScreen extends StatefulWidget {
  final String localPath;
  final String urlFull;
  final String primaryColor;
  final String resolution;
  final int width;
  final int height;

  const WallpaperEditorScreen({
    super.key,
    required this.localPath,
    required this.urlFull,
    required this.primaryColor,
    required this.resolution,
    required this.width,
    required this.height,
  });

  @override
  State<WallpaperEditorScreen> createState() => _WallpaperEditorScreenState();
}

class _WallpaperEditorScreenState extends State<WallpaperEditorScreen>
    with SingleTickerProviderStateMixin {
  double _rotation = 0;
  bool _isApplying = false;
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addListener(() {
          if (_zoomAnimation != null) {
            _transformationController.value = _zoomAnimation!.value;
          }
        });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _rotateLeft() {
    HapticFeedback.lightImpact();
    setState(() => _rotation -= math.pi / 2);
  }

  void _rotateRight() {
    HapticFeedback.lightImpact();
    setState(() => _rotation += math.pi / 2);
  }

  void _resetView() {
    HapticFeedback.lightImpact();
    _transformationController.value = Matrix4.identity();
    setState(() => _rotation = 0);
  }

  void _handleDoubleTap(TapDownDetails details) {
    HapticFeedback.lightImpact();
    final currentMatrix = _transformationController.value;
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
    final ambientColor = ColorUtils.hexToColor(widget.primaryColor);
    final file = File(widget.localPath);
    late final bool hasLocalFile;
    try {
      hasLocalFile = file.existsSync();
    } catch (_) {
      hasLocalFile = false;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                ambientColor.withValues(alpha: 0.3),
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
                  child: hasLocalFile
                      ? Image.file(file, fit: BoxFit.cover)
                      : Image.network(widget.urlFull, fit: BoxFit.cover),
                ),
              ),
            ),
          ).animate().fade(duration: 600.ms),

          Container(
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

          GestureDetector(
            onDoubleTapDown: _handleDoubleTap,
            onVerticalDragUpdate: (details) {
              final scale = _transformationController.value.getMaxScaleOnAxis();
              if (scale <= 1.1 && (details.primaryDelta ?? 0) > 10) {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
              }
            },
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 5.0,
              panEnabled: true,
              scaleEnabled: true,
              child: Center(
                child: Transform.rotate(
                  angle: _rotation,
                  child: hasLocalFile
                      ? Image.file(file, fit: BoxFit.contain)
                      : Image.network(
                          widget.urlFull,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, p) => p == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    ambientColor.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                child: _EditorFrostedButton(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                ),
              )
              .animate()
              .fade(duration: 400.ms, delay: 200.ms)
              .slideX(begin: -0.2, end: 0),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                40,
                24,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFloatingControlDock(),
                  const SizedBox(height: 24),
                  _buildApplyButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingControlDock() {
    final degrees = (_rotation * 180 / math.pi).round() % 360;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EditorCircleButton(
                icon: HugeIcons.strokeRoundedImageCounterClockwise,
                onTap: _rotateLeft,
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Text(
                    '$degrees\u00B0',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ROTATION',
                    style: GoogleFonts.oswald(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              _EditorCircleButton(
                icon: HugeIcons.strokeRoundedImageRotationClockwise,
                onTap: _rotateRight,
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.white.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _EditorCircleButton(
                icon: HugeIcons.strokeRoundedFilter,
                onTap: _resetView,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isApplying
            ? null
            : () {
                HapticFeedback.mediumImpact();
                _showTargetDialog();
              },
        icon: _isApplying
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const HugeIcon(
                icon: HugeIcons.strokeRoundedImage01,
                color: Colors.black,
              ),
        label: Text(
          _isApplying ? 'APPLYING...' : 'APPLY WALLPAPER',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.black,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorUtils.hexToColor(widget.primaryColor),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showTargetDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ).animate().fade(duration: 400.ms).slideY(begin: 0.5, end: 0),
                  const SizedBox(height: 32),
                  Text(
                        'SET WALLPAPER',
                        style: GoogleFonts.oswald(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.5,
                          color: Colors.white,
                        ),
                      )
                      .animate()
                      .fade(duration: 400.ms, delay: 80.ms)
                      .slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 32),
                  _buildTargetOption(
                    'HOME SCREEN',
                    HugeIcons.strokeRoundedHome01,
                    WallpaperTarget.home,
                    100,
                  ),
                  const SizedBox(height: 12),
                  _buildTargetOption(
                    'LOCK SCREEN',
                    HugeIcons.strokeRoundedLock,
                    WallpaperTarget.lock,
                    200,
                  ),
                  const SizedBox(height: 12),
                  _buildTargetOption(
                    'BOTH SCREENS',
                    HugeIcons.strokeRoundedSmartPhone01,
                    WallpaperTarget.both,
                    300,
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTargetOption(
    String title,
    dynamic icon,
    WallpaperTarget target,
    int delay,
  ) {
    return _TargetOption(
      title: title,
      icon: icon,
      target: target,
      delay: delay,
      onApply: () {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _applyWallpaper(target);
        });
      },
    );
  }

  Future<void> _applyWallpaper(WallpaperTarget target) async {
    if (_isApplying) return;
    setState(() => _isApplying = true);

    try {
      final hasLocalFile = File(widget.localPath).existsSync();
      final WallpaperResult result = await AsyncWallpaper.setWallpaper(
        WallpaperRequest(
          target: target,
          sourceType: hasLocalFile
              ? WallpaperSourceType.file
              : WallpaperSourceType.url,
          source: hasLocalFile ? widget.localPath : widget.urlFull,
          goToHome: true,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper set successfully!')),
        );
        Navigator.of(context).pop();
      } else {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed: ${result.error?.message ?? "Unknown error"}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isApplying = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class _EditorFrostedButton extends StatefulWidget {
  final dynamic icon;
  final VoidCallback onTap;

  const _EditorFrostedButton({required this.icon, required this.onTap});

  @override
  State<_EditorFrostedButton> createState() => _EditorFrostedButtonState();
}

class _EditorFrostedButtonState extends State<_EditorFrostedButton> {
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
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: HugeIcon(icon: widget.icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorCircleButton extends StatefulWidget {
  final dynamic icon;
  final VoidCallback onTap;

  const _EditorCircleButton({required this.icon, required this.onTap});

  @override
  State<_EditorCircleButton> createState() => _EditorCircleButtonState();
}

class _EditorCircleButtonState extends State<_EditorCircleButton> {
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
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: HugeIcon(icon: widget.icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _TargetOption extends StatefulWidget {
  final String title;
  final dynamic icon;
  final WallpaperTarget target;
  final int delay;
  final VoidCallback onApply;

  const _TargetOption({
    required this.title,
    required this.icon,
    required this.target,
    required this.delay,
    required this.onApply,
  });

  @override
  State<_TargetOption> createState() => _TargetOptionState();
}

class _TargetOptionState extends State<_TargetOption> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onApply,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              HugeIcon(icon: widget.icon, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: Colors.white.withValues(alpha: 0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
