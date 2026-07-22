import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme_config.dart';
import '../models/wallpaper.dart';
import '../utils/color_utils.dart';

class SpecsCard extends StatelessWidget {
  final Wallpaper wallpaper;

  const SpecsCard({super.key, required this.wallpaper});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: vk.glassBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: vk.glassBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    wallpaper.resolution.replaceAll('x', ' × '),
                    style: GoogleFonts.oswald(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      wallpaper.formattedFileSize,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: vk.onSurfaceSubtle,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: vk.glassBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: vk.glassBorder, width: 0.5),
                    ),
                    child: Text(
                      wallpaper.sourceQuery.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _chip(context, '${wallpaper.width}×${wallpaper.height}', Icons.aspect_ratio),
                  const SizedBox(width: 8),
                  _chip(context, wallpaper.aspectRatio.toStringAsFixed(2), Icons.crop_square),
                  const SizedBox(width: 8),
                  if (wallpaper.category.isNotEmpty)
                    _chip(context, wallpaper.category[0].toUpperCase() + wallpaper.category.substring(1), Icons.category),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: ColorUtils.hexToColor(wallpaper.primaryColor),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: vk.glassBorder, width: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    wallpaper.primaryColor.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: vk.onSurfaceSubtle,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ID: ${wallpaper.wallhavenId}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: vk.onSurfaceFaint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, IconData icon) {
    final vk = context.vivek;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: vk.glassBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: vk.glassBorder, width: 0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: vk.onSurfaceSubtle),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: vk.onSurfaceSubtle,
            ),
          ),
        ],
      ),
    );
  }
}
