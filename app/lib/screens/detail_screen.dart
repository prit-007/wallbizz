import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/wallpaper.dart';
import '../utils/color_utils.dart';
import '../widgets/dynamic_theme.dart';
import '../widgets/specs_card.dart';

class DetailScreen extends StatelessWidget {
  final Wallpaper wallpaper;

  const DetailScreen({super.key, required this.wallpaper});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: DynamicTheme(
        primaryColor: wallpaper.primaryColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen image
            CachedNetworkImage(
              imageUrl: wallpaper.urlFull,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error, color: Colors.white24, size: 48),
              ),
            ),

            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),

            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            // Bottom content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpecsCard(wallpaper: wallpaper),
                    const SizedBox(height: 20),

                    // Download button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadWallpaper(context),
                        icon: const Icon(Icons.download),
                        label: Text(
                          'Download Wallpaper',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              ColorUtils.hexToColor(wallpaper.primaryColor),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Set as Wallpaper (Android only — safe on web via kIsWeb)
                    if (!kIsWeb) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => _setWallpaper(context),
                          icon: const Icon(Icons.wallpaper),
                          label: Text(
                            'Set as Wallpaper',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().slideY(begin: 0.3, end: 0).fade(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadWallpaper(BuildContext context) async {
    final url = Uri.parse(wallpaper.urlFull);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _setWallpaper(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wallpaper setting requires native Android build'),
      ),
    );
  }
}
