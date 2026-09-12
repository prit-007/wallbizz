import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme_config.dart';
import '../services/gallery_service.dart';
import '../widgets/auth_bottom_sheet.dart';
import '../core/updates/update_checker.dart';
import '../core/updates/widgets/update_dialog.dart';
import 'logs_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  String _storageChoice = 'pictures';
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (mounted) setState(() => _user = event.session?.user);
    });
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = await GalleryService.selectedStorage;
    if (mounted) {
      setState(() {
        _isDarkMode = ThemeConfig.isDarkMode.value;
        _storageChoice = storage;
      });
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signed out successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = Theme.of(ctx).colorScheme;
        final v = ctx.vivek;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: v.surfaceContainer.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: v.glassBorder.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                          Icons.person_off_rounded,
                          size: 48,
                          color: Colors.redAccent.withValues(alpha: 0.9),
                        )
                        .animate()
                        .fade(duration: 400.ms)
                        .scale(
                          begin: const Offset(0.6, 0.6),
                          end: const Offset(1, 1),
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(height: 16),
                    Text(
                          'DELETE ACCOUNT',
                          style: GoogleFonts.oswald(
                            fontSize: 22,
                            color: c.onSurface,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        )
                        .animate()
                        .fade(duration: 400.ms, delay: 100.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 12),
                    Text(
                          'This will permanently delete your account and all wishlist data. This action cannot be undone.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: c.onSurface.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        )
                        .animate()
                        .fade(duration: 400.ms, delay: 180.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: v.glassBorder.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'CANCEL',
                                  style: GoogleFonts.inter(
                                    color: v.onSurfaceSubtle,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'DELETE',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fade(duration: 400.ms, delay: 260.ms),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await Supabase.instance.client.auth.admin.deleteUser(_user!.id);
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleTheme(bool value) async {
    await ThemeConfig.setDarkMode(value);
    if (mounted) {
      setState(() => _isDarkMode = value);
    }
  }

  Future<void> _selectStorage(String key) async {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    if (key == 'app_private') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: vk.surfaceContainer.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: vk.glassBorder.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                          Icons.warning_amber_rounded,
                          size: 48,
                          color: Colors.orange.withValues(alpha: 0.8),
                        )
                        .animate()
                        .fade(duration: 400.ms)
                        .scale(
                          begin: const Offset(0.6, 0.6),
                          end: const Offset(1, 1),
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(height: 16),
                    Text(
                          'Private Storage?',
                          style: GoogleFonts.oswald(
                            fontSize: 22,
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        )
                        .animate()
                        .fade(duration: 400.ms, delay: 100.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 12),
                    Text(
                          'Images saved to app storage will be deleted when you uninstall the app and won\'t appear in your gallery.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: cs.onSurface.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        )
                        .animate()
                        .fade(duration: 400.ms, delay: 180.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: vk.glassBorder.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'CANCEL',
                                  style: GoogleFonts.inter(
                                    color: vk.onSurfaceSubtle,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'USE ANYWAY',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fade(duration: 400.ms, delay: 260.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      if (confirmed != true) return;
    }

    await GalleryService.setSelectedStorage(key);
    if (mounted) {
      setState(() => _storageChoice = key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomInset + 100),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          'PREFERENCES',
          style: GoogleFonts.oswald(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: cs.primary,
            letterSpacing: 3,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Customize your experience',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: vk.onSurfaceSubtle,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 32),

        // Dark Mode Card
        Container(
          decoration: BoxDecoration(
            color: vk.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: vk.glassBorder.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              title: Text(
                'Dark Mode',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              subtitle: Text(
                'Use dark theme throughout the app',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: vk.onSurfaceSubtle,
                ),
              ),
              value: _isDarkMode,
              onChanged: _toggleTheme,
              activeTrackColor: cs.primary.withValues(alpha: 0.3),
              inactiveThumbColor: vk.onSurfaceSubtle,
              inactiveTrackColor: vk.surfaceContainerLow,
            ),
          ),
        ),

        const SizedBox(height: 40),

        Text(
          'DOWNLOAD LOCATION',
          style: GoogleFonts.oswald(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: vk.onSurfaceSubtle,
          ),
        ),
        const SizedBox(height: 16),

        _buildStorageOption(
          key: 'pictures',
          title: 'Pictures',
          subtitle: 'Visible in gallery, persists after uninstall',
          icon: Icons.photo_library_outlined,
          colorAccent: Colors.blueAccent,
        ),
        const SizedBox(height: 12),
        _buildStorageOption(
          key: 'download',
          title: 'Downloads',
          subtitle: 'Visible in Files app, persists after uninstall',
          icon: Icons.download_outlined,
          colorAccent: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildStorageOption(
          key: 'app_private',
          title: 'App Storage',
          subtitle: 'Hidden from gallery, deleted with app',
          icon: Icons.lock_outline_rounded,
          colorAccent: Colors.orange,
        ),

        const SizedBox(height: 40),

        Text(
          'ACCOUNT',
          style: GoogleFonts.oswald(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: vk.onSurfaceSubtle,
          ),
        ).animate().fade(duration: 300.ms),
        const SizedBox(height: 16),

        if (_user != null) ...[
          Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: vk.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: vk.glassBorder.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_rounded, size: 20, color: cs.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Signed in as',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: vk.onSurfaceSubtle,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _user!.email ?? 'Unknown',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          'SIGN OUT',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.onSurface.withValues(alpha: 0.15),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _deleteAccount,
                        icon: const Icon(Icons.person_off_rounded, size: 18),
                        label: Text(
                          'DELETE ACCOUNT',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(
                            alpha: 0.15,
                          ),
                          foregroundColor: Colors.redAccent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fade(duration: 300.ms, delay: 100.ms)
              .slideY(begin: 0.1, end: 0),
        ] else ...[
          SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showAuthBottomSheet(context);
                  },
                  icon: const Icon(
                    Icons.login_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    'SIGN IN',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              )
              .animate()
              .fade(duration: 300.ms, delay: 100.ms)
              .slideY(begin: 0.1, end: 0),
        ],

        const SizedBox(height: 40),

        Text(
          'ABOUT',
          style: GoogleFonts.oswald(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: vk.onSurfaceSubtle,
          ),
        ),
        const SizedBox(height: 16),

        _buildSettingsTile(
          icon: Icons.description_outlined,
          title: 'App Logs',
          subtitle: 'View system diagnostics and debug info',
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LogsScreen()));
          },
        ),
        const SizedBox(height: 12),
        _buildSettingsTile(
          icon: Icons.system_update_rounded,
          title: 'Check for Updates',
          subtitle: 'Wallbizz v1.1.0',
          onTap: () async {
            final info = await PackageInfo.fromPlatform();
            final checker = UpdateChecker();
            final update = await checker.checkForUpdate(info.version);
            if (!context.mounted) return;
            if (update != null) {
              UpdateDialog.show(context, update);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You\'re up to date!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _buildSettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'About Wallbizz',
          subtitle: 'Premium curated wallpapers',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: vk.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: vk.glassBorder.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: cs.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: vk.onSurfaceSubtle,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: vk.onSurfaceSubtle,
              size: 22,
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStorageOption({
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color colorAccent,
  }) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final isSelected = _storageChoice == key;

    return GestureDetector(
      onTap: () => _selectStorage(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? vk.surfaceOverlay : vk.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? cs.primary
                : vk.glassBorder.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.15)
                    : vk.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? cs.primary : vk.onSurfaceSubtle,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: key == 'app_private'
                          ? colorAccent.withValues(alpha: 0.9)
                          : vk.onSurfaceSubtle,
                      fontWeight: key == 'app_private'
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isSelected ? 1.0 : 0.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 250),
                scale: isSelected ? 1.0 : 0.5,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: cs.primary,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
