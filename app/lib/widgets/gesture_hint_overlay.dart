import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _GestureHintOverlayState extends State<GestureHintOverlay> {
  bool _showHints = false;

  @override
  void initState() {
    super.initState();
    _checkHints();
  }

  Future<void> _checkHints() async {
    final show = await GestureHintOverlay.shouldShow();
    if (mounted && show) {
      HapticFeedback.lightImpact();
      setState(() => _showHints = true);
    }
  }

  void _dismiss() {
    HapticFeedback.selectionClick();
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
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: 0.75)),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _HintTile(
                          icon: Icons.swipe_down_rounded,
                          title: 'SWIPE DOWN TO CLOSE',
                          subtitle: 'Quickly dismiss full screen viewer',
                          delay: 150,
                        ),
                        const SizedBox(height: 20),
                        const _HintTile(
                          icon: Icons.tap_and_play_rounded,
                          title: 'TAP IMAGE TO HIDE UI',
                          subtitle: 'Toggle controls for an unobstructed view',
                          delay: 250,
                        ),
                        const SizedBox(height: 20),
                        const _HintTile(
                          icon: Icons.touch_app_rounded,
                          title: 'DOUBLE-TAP TO ZOOM',
                          subtitle: 'Seamless 2.5x physics zoom',
                          delay: 450,
                        ),
                        const SizedBox(height: 20),
                        const _HintTile(
                          icon: Icons.favorite_rounded,
                          title: 'HEART TO SAVE',
                          subtitle: 'Sync across all your devices',
                          delay: 650,
                        ),
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            'TAP ANYWHERE TO CONTINUE',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ).animate().fade(delay: 800.ms).slideY(begin: 0.2, end: 0),
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
  final String subtitle;
  final int delay;

  const _HintTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.oswald(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(delay: delay.ms).slideX(begin: -0.1, end: 0);
  }
}
