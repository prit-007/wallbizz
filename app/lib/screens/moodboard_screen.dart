import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme_config.dart';
import '../models/moodboard.dart';
import '../models/wallpaper.dart';
import '../services/supabase_service.dart';
import '../widgets/network_image.dart';
import 'detail_screen.dart';

class MoodboardScreen extends StatefulWidget {
  final Moodboard moodboard;

  const MoodboardScreen({super.key, required this.moodboard});

  @override
  State<MoodboardScreen> createState() => _MoodboardScreenState();
}

class _MoodboardScreenState extends State<MoodboardScreen> {
  List<Wallpaper> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await SupabaseService.instance.fetchMoodboardItems(widget.moodboard.id);
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _removeItemOptimistically(int index, Wallpaper wallpaper) async {
    HapticFeedback.mediumImpact();
    setState(() => _items.removeAt(index));

    bool undoClicked = false;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Text(
                    'Removed from moodboard',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      undoClicked = true;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      setState(() => _items.insert(index, wallpaper));
                    },
                    child: Text(
                      'UNDO',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
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

    await Future.delayed(const Duration(seconds: 4));
    if (!undoClicked) {
      await SupabaseService.instance.removeFromMoodboard(widget.moodboard.id, wallpaper.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: vk.surfaceContainer,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: vk.glassBorder.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.moodboard.name.toUpperCase(),
                          style: GoogleFonts.oswald(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2.5,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CURATED ARCHIVE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: vk.onSurfaceSubtle,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: vk.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: vk.glassBorder.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      '${_items.length} ITEMS',
                      style: GoogleFonts.oswald(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2))
                  : _items.isEmpty
                      ? _buildEmptyView(vk)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: cs.primary,
                          backgroundColor: Colors.black,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
                              return MasonryGridView.count(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding + 32),
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  final wallpaper = _items[index];
                                  return _MoodboardCard(
                                    wallpaper: wallpaper,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(wallpaper: wallpaper)));
                                    },
                                    onLongPress: () => _removeItemOptimistically(index, wallpaper),
                                  ).animate().fade(duration: 350.ms).slideY(begin: 0.1, end: 0, delay: Duration(milliseconds: (index % crossAxisCount) * 40));
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(dynamic vk) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: vk.surfaceContainer, shape: BoxShape.circle),
              child: Icon(Icons.dashboard_customize_rounded, size: 48, color: vk.onSurfaceDim),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.08, duration: 1500.ms, curve: Curves.easeInOut),
            const SizedBox(height: 24),
            Text(
              'EMPTY MOODBOARD',
              style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Long press or tap "Add to Moodboard" from any wallpaper detail view to populate this canvas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: vk.onSurfaceSubtle, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodboardCard extends StatefulWidget {
  final Wallpaper wallpaper;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MoodboardCard({
    required this.wallpaper,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_MoodboardCard> createState() => _MoodboardCardState();
}

class _MoodboardCardState extends State<_MoodboardCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: widget.wallpaper.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetworkImageWidget(imageUrl: widget.wallpaper.urlThumb, fit: BoxFit.cover),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8, left: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        color: Colors.black.withValues(alpha: 0.35),
                        child: Text(
                          widget.wallpaper.resolution,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
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
    );
  }
}
