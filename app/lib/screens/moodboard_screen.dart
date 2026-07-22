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

  Future<void> _removeItem(int index) async {
    final wallpaper = _items[index];
    setState(() => _items.removeAt(index));
    await SupabaseService.instance.removeFromMoodboard(widget.moodboard.id, wallpaper.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: vk.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: vk.glassBorder),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface, size: 18),
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
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                            letterSpacing: 2,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_items.length} ITEMS',
                          style: GoogleFonts.inter(fontSize: 11, color: vk.onSurfaceSubtle, letterSpacing: 1.5, fontWeight: FontWeight.w600),
                        ),
                      ],
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
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 3 : 2;
                              return MasonryGridView.count(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding + 90),
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  final wallpaper = _items[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(wallpaper: wallpaper)));
                                    },
                                    onLongPress: () => _removeItem(index),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: AspectRatio(
                                        aspectRatio: wallpaper.aspectRatio,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            NetworkImageWidget(imageUrl: wallpaper.urlThumb, fit: BoxFit.cover),
                                            Positioned(
                                              bottom: 0, left: 0, right: 0,
                                              child: Container(
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
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
                                                    child: Text(wallpaper.resolution, style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
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
            ),
            const SizedBox(height: 24),
            Text(
              'EMPTY MOODBOARD',
              style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Add wallpapers from detail view to curate this collection.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: vk.onSurfaceSubtle, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
