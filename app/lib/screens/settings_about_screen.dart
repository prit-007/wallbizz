import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/theme_config.dart';
import '../widgets/wallbizz_logo.dart';

class SettingsAboutScreen extends StatefulWidget {
  const SettingsAboutScreen({super.key});

  @override
  State<SettingsAboutScreen> createState() => _SettingsAboutScreenState();
}

class _SettingsAboutScreenState extends State<SettingsAboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          'Manifesto',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
        children: [
          const SizedBox(height: 32),
          Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: vk.surfaceContainerHigh.withValues(alpha: 0.3),
                border: Border.all(
                  color: vk.glassBorder.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const WallbizzLogo(size: 56),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Wallbizz',
            textAlign: TextAlign.center,
            style: GoogleFonts.oswald(
              fontSize: 72,
              fontWeight: FontWeight.w400,
              letterSpacing: -4.0,
              height: 0.9,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'EDITION ${_version.isNotEmpty ? _version : '\u2014'}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: cs.primary,
              letterSpacing: 4.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Premium curated wallpapers, delivered with precision.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: vk.onSurfaceSubtle,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 64),
          _SectionHeader(title: 'THE VISION'),
          const SizedBox(height: 16),
          _GlassCard(
            child: Text(
              'Born from a single obsession: wallpapers should not just fill '
              'a screen\u2014they should define it. Every pixel is curated, '
              'every interaction crafted to feel like flipping through a '
              'gallery of digital art.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: cs.onSurface,
                height: 1.8,
                letterSpacing: -0.2,
              ),
            ),
          ),

          const SizedBox(height: 40),
          _SectionHeader(title: 'CRAFTED EXPERIENCE'),
          const SizedBox(height: 16),
          _GlassCard(
            child: Text(
              'A glassmorphic interface designed to disappear. Fluid animations, '
              'macro-typography, and gesture-driven navigation put the '
              'wallpapers front and center. The app adapts to your rhythm\u2014'
              'swipe, tap, and explore without friction.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: cs.onSurface,
                height: 1.8,
                letterSpacing: -0.2,
              ),
            ),
          ),

          const SizedBox(height: 40),
          _SectionHeader(title: 'PRIVACY FIRST'),
          const SizedBox(height: 16),
          _GlassCard(
            child: Text(
              'No analytics. No tracking. No cloud sync of your personal '
              'data. Your wishlist lives on your device, encrypted and '
              'private. When you authenticate, it\u2019s solely to sync your '
              'own data across your own devices\u2014nothing more.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: cs.onSurface,
                height: 1.8,
                letterSpacing: -0.2,
              ),
            ),
          ),

          const SizedBox(height: 40),
          _SectionHeader(title: 'OPEN FOUNDATION'),
          const SizedBox(height: 16),
          _GlassCard(
            child: Text(
              'Built on open-source technologies: Flutter for cross-platform '
              'precision, Supabase for authentication and data, and the '
              'Wallhaven API for an endless stream of high-quality wallpapers. '
              'Every dependency was chosen with intention.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: cs.onSurface,
                height: 1.8,
                letterSpacing: -0.2,
              ),
            ),
          ),

          const SizedBox(height: 40),
          _SectionHeader(title: 'PROVENANCE'),
          const SizedBox(height: 16),
          _GlassCard(
            child: Text(
              'Engineered with absolute precision by '
              'Prit Vasani. Crafted by Developer\'s Paradise on a foundation '
              'of open-source technologies, driven by a relentless pursuit '
              'of uncompromised quality and luxury design.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: cs.onSurface,
                height: 1.8,
                letterSpacing: -0.2,
              ),
            ),
          ),

          const SizedBox(height: 56),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _Badge(label: 'Flutter'),
              _Badge(label: 'Supabase'),
              _Badge(label: 'Wallhaven API'),
              _Badge(label: 'Go Backend'),
              _Badge(label: 'Developer\'s Paradise'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final vk = context.vivek;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: vk.onSurfaceSubtle,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final vk = context.vivek;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: vk.surfaceContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: vk.glassBorder.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final vk = context.vivek;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: vk.surfaceContainerHigh.withValues(alpha: 0.3),
        border: Border.all(color: vk.glassBorder.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
          color: vk.onSurfaceSubtle,
        ),
      ),
    );
  }
}
