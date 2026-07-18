import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GalleryService {
  static const _channel = MethodChannel('com.vivek.vivek_app/gallery');
  static const _storagePrefKey = 'gallery_storage_choice';

  static const Map<String, String> storageOptions = {
    'pictures': 'Pictures/VivekWallpapers',
    'download': 'Download/VivekWallpapers',
    'app_private': 'App Storage (private)',
  };

  static Future<String> get selectedStorage async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storagePrefKey) ?? 'pictures';
  }

  static Future<void> setSelectedStorage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storagePrefKey, key);
  }

  static Future<String> getTargetDirectory() async {
    final choice = await selectedStorage;

    switch (choice) {
      case 'pictures':
        final result = await _channel.invokeMethod<String>('getGalleryPath', {
          'subDir': 'VivekWallpapers',
        });
        return result ?? '/storage/emulated/0/Pictures/VivekWallpapers';

      case 'download':
        if (Platform.isAndroid) {
          return '/storage/emulated/0/Download/VivekWallpapers';
        }
        final dir = await getApplicationDocumentsDirectory();
        return '${dir.path}/VivekWallpapers';

      case 'app_private':
      default:
        final dir = await getApplicationDocumentsDirectory();
        return '${dir.path}/VivekWallpapers';
    }
  }

  static Future<bool> saveToGallery({
    required String sourcePath,
    required String fileName,
  }) async {
    final choice = await selectedStorage;

    if (choice == 'app_private') {
      return true;
    }

    try {
      final result = await _channel.invokeMethod<bool>('saveToGallery', {
        'sourcePath': sourcePath,
        'fileName': fileName,
        'subDir': 'VivekWallpapers',
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> scanMedia(String filePath) async {
    try {
      await _channel.invokeMethod('scanMedia', {'filePath': filePath});
    } catch (_) {}
  }
}
