import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

Future<void> showSetWallpaperDialog(
  BuildContext context,
  String urlFull,
) async {
  final result = await showModalBottomSheet<WallpaperTarget>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    isScrollControlled: true,
    builder: (context) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
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
              ),
              const SizedBox(height: 32),
              Text(
                'APPLY WALLPAPER',
                style: GoogleFonts.oswald(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.5,
                  color: Colors.white,
                ),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.5, end: 0),
              const SizedBox(height: 32),
              _WallpaperOption(
                title: 'HOME SCREEN',
                icon: Icons.home_rounded,
                target: WallpaperTarget.home,
                urlFull: urlFull,
                delay: 100,
              ),
              const SizedBox(height: 12),
              _WallpaperOption(
                title: 'LOCK SCREEN',
                icon: Icons.lock_rounded,
                target: WallpaperTarget.lock,
                urlFull: urlFull,
                delay: 200,
              ),
              const SizedBox(height: 12),
              _WallpaperOption(
                title: 'BOTH SCREENS',
                icon: Icons.phone_android_rounded,
                target: WallpaperTarget.both,
                urlFull: urlFull,
                delay: 300,
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    ),
  );

  if (result != null && context.mounted) {
    _applyWallpaper(context, urlFull, result);
  }
}

class _WallpaperOption extends StatefulWidget {
  final String title;
  final IconData icon;
  final WallpaperTarget target;
  final String urlFull;
  final int delay;

  const _WallpaperOption({
    required this.title,
    required this.icon,
    required this.target,
    required this.urlFull,
    required this.delay,
  });

  @override
  State<_WallpaperOption> createState() => _WallpaperOptionState();
}

class _WallpaperOptionState extends State<_WallpaperOption> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (context.mounted) Navigator.pop(context, widget.target);
        });
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white, size: 24),
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
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 400.ms, delay: widget.delay.ms).slideX(begin: 0.1, end: 0);
  }
}

Future<void> _applyWallpaper(
  BuildContext context,
  String url,
  WallpaperTarget target,
) async {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'APPLYING WALLPAPER...',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      duration: const Duration(seconds: 5),
    ),
  );

  try {
    final WallpaperResult result = await AsyncWallpaper.setWallpaper(
      WallpaperRequest(
        target: target,
        sourceType: WallpaperSourceType.url,
        source: url,
        goToHome: true,
      ),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.greenAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Text(
            'Wallpaper set successfully!',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Text(
            'Failed: ${result.error?.message ?? "Unknown error"}',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text('Error: $e', style: GoogleFonts.inter()),
      ),
    );
  }
}
