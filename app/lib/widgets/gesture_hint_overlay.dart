import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/responsive_config.dart';

class GestureHintOverlay extends StatefulWidget {
  final Widget child;

  const GestureHintOverlay({super.key, required this.child});

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('gesture_hints_shown_v2') ?? false;
    return !shown;
  }

  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gesture_hints_shown_v2', true);
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
                  child: Container(color: Colors.black.withValues(alpha: 0.82)),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.isDesktop ? 48 : 28,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                                'GESTURE GUIDE',
                                style: GoogleFonts.oswald(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 4,
                                ),
                              )
                              .animate()
                              .fade(delay: 0.ms)
                              .slideY(begin: 0.3, end: 0),
                          const SizedBox(height: 6),
                          Text(
                            'Navigate like a pro',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ).animate().fade(delay: 100.ms),
                          const SizedBox(height: 32),
                          _buildHintsGrid(context),
                          const SizedBox(height: 36),
                          Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Text(
                                  'TAP ANYWHERE TO CONTINUE',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                              .animate()
                              .fade(delay: 900.ms)
                              .slideY(begin: 0.2, end: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHintsGrid(BuildContext context) {
    final hints = [
      _HintData(
        icon: HugeIcons.strokeRoundedSwipeDown01,
        title: 'SWIPE DOWN',
        subtitle: 'Go back from full-screen viewer',
        delay: 150,
      ),
      _HintData(
        icon: HugeIcons.strokeRoundedSwipeLeft01,
        title: 'SWIPE LEFT / RIGHT',
        subtitle: 'Browse wallpapers like a gallery',
        delay: 250,
      ),
      _HintData(
        icon: HugeIcons.strokeRoundedTouch02,
        title: 'TAP TO TOGGLE UI',
        subtitle: 'Hide controls for immersive viewing',
        delay: 350,
      ),
      _HintData(
        icon: HugeIcons.strokeRoundedTouch01,
        title: 'DOUBLE-TAP TO ZOOM',
        subtitle: 'Seamless 2.5x physics zoom',
        delay: 450,
      ),
      _HintData(
        icon: HugeIcons.strokeRoundedFavourite,
        title: 'HEART TO SAVE',
        subtitle: 'Sync across all your devices',
        delay: 550,
      ),
      _HintData(
        icon: HugeIcons.strokeRoundedShare01,
        title: 'SHARE WITH BRAND',
        subtitle: 'Watermarked exports instantly',
        delay: 650,
      ),
    ];

    if (context.isDesktop) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: hints
            .map(
              (h) => SizedBox(
                width: 320,
                child: _HintTile(
                  icon: h.icon,
                  title: h.title,
                  subtitle: h.subtitle,
                  delay: h.delay,
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < hints.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _HintTile(
            icon: hints[i].icon,
            title: hints[i].title,
            subtitle: hints[i].subtitle,
            delay: hints[i].delay,
          ),
        ],
      ],
    );
  }
}

class _HintData {
  final dynamic icon;
  final String title;
  final String subtitle;
  final int delay;

  const _HintData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delay,
  });
}

class _HintTile extends StatelessWidget {
  final dynamic icon;
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
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(icon: icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.oswald(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fade(delay: delay.ms)
        .slideX(begin: -0.08, end: 0, curve: Curves.easeOutCubic);
  }
}
