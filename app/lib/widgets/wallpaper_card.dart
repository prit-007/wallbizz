import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/wallpaper.dart';
import 'hover_builder.dart';
import 'network_image.dart';

class WallpaperCard extends StatefulWidget {
  final Wallpaper wallpaper;
  final VoidCallback? onTap;
  final VoidCallback? onHeartTap;
  final bool isWishlisted;

  const WallpaperCard({
    super.key,
    required this.wallpaper,
    this.onTap,
    this.onHeartTap,
    this.isWishlisted = false,
  });

  @override
  State<WallpaperCard> createState() => _WallpaperCardState();
}

class _WallpaperCardState extends State<WallpaperCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Semantics(
        label: 'Wallpaper ${widget.wallpaper.resolution}',
        button: true,
        child: HoverBuilder(
          builder: (context, isHovered) {
            return GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onTap,
              child: AnimatedScale(
                scale: _isPressed ? 0.96 : (isHovered ? 1.02 : 1.0),
                duration: const Duration(milliseconds: 150),
                curve: Curves.decelerate,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: isHovered
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: widget.wallpaper.aspectRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          NetworkImageWidget(
                            imageUrl: widget.wallpaper.urlThumb,
                            fit: BoxFit.cover,
                          ),

                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.75),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            bottom: 10,
                            left: 10,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  color: Colors.black.withValues(alpha: 0.35),
                                  child: Text(
                                    widget.wallpaper.resolution,
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (widget.onHeartTap != null)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: widget.onHeartTap,
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 8,
                                      sigmaY: 8,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      color: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      child: HugeIcon(
                                        icon: widget.isWishlisted
                                            ? HugeIcons.strokeRoundedFavourite
                                            : HugeIcons.strokeRoundedFavourite,
                                        color: widget.isWishlisted
                                            ? Colors.redAccent
                                            : Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ).animate().fade(duration: 350.ms).slideY(begin: 0.1, end: 0);
  }
}
