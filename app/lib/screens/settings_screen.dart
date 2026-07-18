import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final storage = await GalleryService.selectedStorage;
    if (mounted) {
      setState(() {
        _isDarkMode = prefs.getBool('dark_mode') ?? true;
        _storageChoice = storage;
      });
    }
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    if (mounted) {
      setState(() => _isDarkMode = value);
    }
  }

  Future<void> _selectStorage(String key) async {
    if (key == 'app_private') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Private Storage?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Images saved to app storage will be deleted when you uninstall the app and won\'t appear in your gallery.',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Use Anyway', style: GoogleFonts.inter(color: Colors.white)),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          title: Text(
            'Dark Mode',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          subtitle: Text(
            'Use dark theme throughout the app',
            style: GoogleFonts.inter(color: Colors.white54),
          ),
          value: _isDarkMode,
          onChanged: _toggleTheme,
          activeThumbColor: Colors.white,
          tileColor: Colors.grey[900],
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
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Where should downloaded wallpapers be saved?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white54,
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
    final isSelected = _storageChoice == key;

    return GestureDetector(
      onTap: () => _selectStorage(key),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.4)
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
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white54,
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
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
              const Icon(Icons.check_circle, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}
