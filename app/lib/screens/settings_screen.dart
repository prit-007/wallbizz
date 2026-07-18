import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/download_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  String _downloadPath = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDarkMode = prefs.getBool('dark_mode') ?? true;
        _downloadPath = prefs.getString('download_path') ?? '';
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

  Future<void> _editDownloadPath() async {
    final controller = TextEditingController(text: _downloadPath);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Download Path',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter full directory path',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != _downloadPath) {
      await DownloadService.setDownloadPath(result);
      if (mounted) {
        setState(() => _downloadPath = result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          title: const Text(
            'Dark Mode',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Use dark theme throughout the app',
            style: TextStyle(color: Colors.white54),
          ),
          value: _isDarkMode,
          onChanged: _toggleTheme,
          activeThumbColor: Colors.white,
          tileColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text(
            'Download Location',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            _downloadPath.isNotEmpty ? _downloadPath : 'Default',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.edit, color: Colors.white54, size: 20),
          tileColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: _editDownloadPath,
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text(
            'About',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Vivek Wallpapers v1.0.0',
            style: TextStyle(color: Colors.white54),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
          tileColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}
