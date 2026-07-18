import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme_config.dart';
import '../services/gallery_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  String _storageChoice = 'pictures';

  @override
  void initState() {
    super.initState();
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
        builder: (ctx) => AlertDialog(
          backgroundColor: vk.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Private Storage?',
            style: GoogleFonts.inter(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Images saved to app storage will be deleted when you uninstall the app and won\'t appear in your gallery.',
            style: GoogleFonts.inter(color: cs.onSurface.withValues(alpha: 0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: vk.onSurfaceSubtle)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Use Anyway', style: GoogleFonts.inter(color: cs.onSurface)),
            ),
          ],
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          title: Text(
            'Dark Mode',
            style: GoogleFonts.inter(color: cs.onSurface),
          ),
          subtitle: Text(
            'Use dark theme throughout the app',
            style: GoogleFonts.inter(color: vk.onSurfaceSubtle),
          ),
          value: _isDarkMode,
          onChanged: _toggleTheme,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'STORAGE',
          style: GoogleFonts.oswald(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: vk.onSurfaceSubtle,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Where should downloaded wallpapers be saved?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: vk.onSurfaceSubtle,
          ),
        ),
        const SizedBox(height: 12),
        _buildStorageOption(
          key: 'pictures',
          title: 'Pictures',
          subtitle: 'Pictures/VivekWallpapers',
          icon: Icons.photo_library_outlined,
          description: 'Visible in gallery, persists after uninstall',
        ),
        const SizedBox(height: 8),
        _buildStorageOption(
          key: 'download',
          title: 'Download',
          subtitle: 'Download/VivekWallpapers',
          icon: Icons.download_outlined,
          description: 'Visible in Downloads app, persists after uninstall',
        ),
        const SizedBox(height: 8),
        _buildStorageOption(
          key: 'app_private',
          title: 'App Storage',
          subtitle: 'Private to Vivek Wallpapers',
          icon: Icons.phone_android,
          description: 'Hidden from gallery, deleted with app',
        ),
      ],
    );
  }

  Widget _buildStorageOption({
    required String key,
    required String title,
    required String subtitle,
    required IconData icon,
    required String description,
  }) {
    final cs = Theme.of(context).colorScheme;
    final vk = context.vivek;
    final isSelected = _storageChoice == key;

    return GestureDetector(
      onTap: () => _selectStorage(key),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? vk.surfaceOverlay
              : vk.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? vk.glassBorder
                : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? vk.surfaceOverlay
                    : vk.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? cs.onSurface : vk.onSurfaceSubtle,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: vk.onSurfaceSubtle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: key == 'app_private'
                          ? Colors.orange.withValues(alpha: 0.8)
                          : Colors.green.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: cs.onSurface, size: 22),
          ],
        ),
      ),
    );
  }
}
