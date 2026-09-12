import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme_config.dart';
import '../models/downloaded_wallpaper.dart';

class LocalWallpaperCard extends StatelessWidget {
  final DownloadedWallpaper wallpaper;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const LocalWallpaperCard({
    super.key,
    required this.wallpaper,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final file = File(wallpaper.localPath);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: wallpaper.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : Container(
                      color: vk.surfaceContainer,
                      child: Icon(Icons.broken_image, color: vk.onSurfaceDim),
                    ),
              if (isSelected)
                Container(color: cs.primary.withValues(alpha: 0.25)),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    wallpaper.resolution,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary
                        : Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.check,
                    color: cs.onSurface,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.15, end: 0);
  }
}
