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
    final vk = context.vivek;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      wallpaper.formattedFileSize,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
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
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      wallpaper.sourceQuery.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: ColorUtils.hexToColor(wallpaper.primaryColor),
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
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    wallpaper.primaryColor.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ID: ${wallpaper.wallhavenId}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.4),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.3,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
