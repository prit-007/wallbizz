import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme_config.dart';
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

class _WallpaperEditorScreenState extends State<WallpaperEditorScreen> {
  double _rotation = 0;
  bool _isApplying = false;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _rotateLeft() {
    setState(() => _rotation -= math.pi / 2);
  }

  void _rotateRight() {
    setState(() => _rotation += math.pi / 2);
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
    setState(() => _rotation = 0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final file = File(widget.localPath);
    final hasLocalFile = file.existsSync();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 5.0,
            panEnabled: true,
            scaleEnabled: true,
            child: Center(
              child: Transform.rotate(
                angle: _rotation,
                child: hasLocalFile
                    ? Image.file(
                        file,
                        fit: BoxFit.contain,
                      )
                    : Image.network(
                        widget.urlFull,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(color: vk.onSurfaceDim),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(Icons.error_outline, color: vk.onSurfaceDim),
                          );
                        },
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
                  color: Colors.black.withValues(alpha: 0.5),
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
              onTap: _resetView,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.center_focus_strong,
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
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRotationPreview(),
                  const SizedBox(height: 16),
                  _buildRotationButtons(),
                  const SizedBox(height: 16),
                  _buildApplyButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotationPreview() {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final degrees = (_rotation * 180 / math.pi).round() % 360;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: vk.glassBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.screen_rotation,
            color: cs.onSurface.withValues(alpha: 0.7),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$degrees°',
            style: GoogleFonts.inter(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${widget.width} × ${widget.height}',
            style: GoogleFonts.inter(
              color: vk.onSurfaceSubtle,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleButton(
          icon: Icons.rotate_left,
          onTap: _rotateLeft,
        ),
        const SizedBox(width: 24),
        _buildCircleButton(
          icon: Icons.rotate_right,
          onTap: _rotateRight,
        ),
        const SizedBox(width: 24),
        _buildCircleButton(
          icon: Icons.restart_alt,
          onTap: _resetView,
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: vk.glassBackground,
          shape: BoxShape.circle,
          border: Border.all(
            color: vk.glassBorder,
          ),
        ),
        child: Icon(icon, color: cs.onSurface, size: 24),
      ),
    );
  }

  Widget _buildApplyButton() {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isApplying ? null : _showTargetDialog,
        icon: _isApplying
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onSurface,
                ),
              )
            : const Icon(Icons.wallpaper),
        label: Text(
          _isApplying ? 'Applying...' : 'Apply Wallpaper',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorUtils.hexToColor(widget.primaryColor),
          foregroundColor: cs.onSurface,
          disabledBackgroundColor: vk.surfaceOverlay,
          disabledForegroundColor: vk.onSurfaceSubtle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
        final cs = Theme.of(context).colorScheme;
        final vk = context.vivek;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: vk.glassBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: vk.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'SET WALLPAPER',
                style: GoogleFonts.oswald(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              _buildTargetOption('Home Screen', Icons.home_outlined, WallpaperTarget.home),
              const SizedBox(height: 8),
              _buildTargetOption('Lock Screen', Icons.lock_outline, WallpaperTarget.lock),
              const SizedBox(height: 8),
              _buildTargetOption('Both Screens', Icons.phone_android, WallpaperTarget.both),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTargetOption(String title, IconData icon, WallpaperTarget target) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pop(context);
          _applyWallpaper(target);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: vk.glassBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: vk.glassBackground,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: cs.onSurface.withValues(alpha: 0.7), size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: vk.glassBorder,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyWallpaper(WallpaperTarget target) async {
    if (_isApplying) return;

    setState(() => _isApplying = true);

    if (mounted) {
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Applying wallpaper...'),
            ],
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    }

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
            content: Text('Failed: ${result.error?.message ?? "Unknown error"}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isApplying = false);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
