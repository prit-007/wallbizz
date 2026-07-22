import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GestureHintOverlay extends StatefulWidget {
  final Widget child;

  const GestureHintOverlay({super.key, required this.child});

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('gesture_hints_shown') ?? false;
    return !shown;
  }

  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gesture_hints_shown', true);
  }

  @override
  State<GestureHintOverlay> createState() => _GestureHintOverlayState();
}

class _GestureHintOverlayState extends State<GestureHintOverlay> with SingleTickerProviderStateMixin {
  bool _showHints = false;

  @override
  void initState() {
    super.initState();
    _checkHints();
  }

  Future<void> _checkHints() async {
    final show = await GestureHintOverlay.shouldShow();
    if (mounted && show) {
      setState(() => _showHints = true);
    }
  }

  void _dismiss() {
    GestureHintOverlay.markShown();
    setState(() => _showHints = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showHints)
          GestureDetector(
            onTap: _dismiss,
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(color: Colors.black.withValues(alpha: 0.5)),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HintTile(
                          icon: Icons.swipe_down_rounded,
                          title: 'SWIPE DOWN TO CLOSE',
                          delay: 200,
                        ),
                        const SizedBox(height: 32),
                        _HintTile(
                          icon: Icons.touch_app_rounded,
                          title: 'DOUBLE-TAP TO ZOOM',
                          delay: 500,
                        ),
                        const SizedBox(height: 32),
                        _HintTile(
                          icon: Icons.favorite_rounded,
                          title: 'HEART TO SAVE',
                          delay: 800,
                        ),
                        const SizedBox(height: 48),
                        Text(
                          'TAP ANYWHERE TO DISMISS',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate().fade(delay: 1200.ms),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HintTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int delay;

  const _HintTile({
    required this.icon,
    required this.title,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ).animate().fade(delay: delay.ms).slideX(begin: -0.2, end: 0).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
        const SizedBox(width: 20),
        Text(
          title,
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ).animate().fade(delay: (delay + 150).ms).slideX(begin: 0.1, end: 0),
      ],
    );
  }
}
