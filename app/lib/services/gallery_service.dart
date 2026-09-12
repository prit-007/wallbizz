import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GalleryService {
  static const _channel = MethodChannel('com.wallbizz.app/gallery');
  static const _storagePrefKey = 'gallery_storage_choice';

  static bool get _isDesktop =>
      !kIsWeb && !Platform.isAndroid && !Platform.isIOS;

  static const Map<String, String> storageOptions = {
    'pictures': 'Pictures/Wallbizz',
    'download': 'Download/Wallbizz',
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
    if (_isDesktop) {
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/Wallbizz';
    }

    final choice = await selectedStorage;

    switch (choice) {
      case 'pictures':
        try {
          final result = await _channel.invokeMethod<String>('getGalleryPath', {
            'subDir': 'Wallbizz',
          });
          return result ?? '/storage/emulated/0/Pictures/Wallbizz';
        } catch (_) {
          final dir = await getApplicationDocumentsDirectory();
          return '${dir.path}/Wallbizz';
        }

      case 'download':
        if (Platform.isAndroid) {
          return '/storage/emulated/0/Download/Wallbizz';
        }
        final dir = await getApplicationDocumentsDirectory();
        return '${dir.path}/Wallbizz';

      case 'app_private':
      default:
        final dir = await getApplicationDocumentsDirectory();
        return '${dir.path}/Wallbizz';
    }
  }

  static Future<bool> saveToGallery({
    required String sourcePath,
    required String fileName,
  }) async {
    if (_isDesktop) return true;

    final choice = await selectedStorage;
    if (choice == 'app_private') return true;

    try {
      final result = await _channel.invokeMethod<bool>('saveToGallery', {
        'sourcePath': sourcePath,
        'fileName': fileName,
        'subDir': 'Wallbizz',
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> scanMedia(String filePath) async {
    if (_isDesktop) return;
    try {
      await _channel.invokeMethod('scanMedia', {'filePath': filePath});
    } catch (_) {}
  }
}
