import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showSetWallpaperDialog(
  BuildContext context,
  String urlFull,
) async {
  final result = await showModalBottomSheet<WallpaperTarget>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'APPLY WALLPAPER',
                style: GoogleFonts.oswald(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              _WallpaperOption(
                title: 'Home Screen',
                icon: Icons.home_outlined,
                target: WallpaperTarget.home,
                urlFull: urlFull,
              ),
              const SizedBox(height: 8),
              _WallpaperOption(
                title: 'Lock Screen',
                icon: Icons.lock_outline,
                target: WallpaperTarget.lock,
                urlFull: urlFull,
              ),
              const SizedBox(height: 8),
              _WallpaperOption(
                title: 'Both Screens',
                icon: Icons.phone_android,
                target: WallpaperTarget.both,
                urlFull: urlFull,
              ),
              const SizedBox(height: 16),
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

class _WallpaperOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final WallpaperTarget target;
  final String urlFull;

  const _WallpaperOption({
    required this.title,
    required this.icon,
    required this.target,
    required this.urlFull,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pop(context, target),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.3),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _applyWallpaper(
  BuildContext context,
  String url,
  WallpaperTarget target,
) async {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Text('Downloading and applying wallpaper...'),
        ],
      ),
      duration: Duration(seconds: 5),
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
        const SnackBar(content: Text('Wallpaper set successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${result.error?.message ?? "Unknown error"}'),
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
