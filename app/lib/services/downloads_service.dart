import 'dart:io';
import 'package:hive/hive.dart';
import '../models/downloaded_wallpaper.dart';
import '../models/wallpaper.dart';
import 'download_service.dart';
import 'gallery_service.dart';

class DownloadsService {
  static const String _boxName = 'downloads';
  static Box get _box => Hive.box(_boxName);

  static Future<void> downloadAndSave(Wallpaper wallpaper) async {
    final targetDir = await GalleryService.getTargetDirectory();
    final dir = Directory(targetDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final fileName = '${wallpaper.wallhavenId}.jpg';

    final filePath = await DownloadService.downloadImage(
      imageUrl: wallpaper.urlFull,
      fileName: fileName,
      savePath: targetDir,
    );

    await GalleryService.saveToGallery(
      sourcePath: filePath,
      fileName: fileName,
    );

    final record = DownloadedWallpaper(
      wallhavenId: wallpaper.wallhavenId,
      localPath: filePath,
      urlFull: wallpaper.urlFull,
      urlThumb: wallpaper.urlThumb,
      sourceQuery: wallpaper.sourceQuery,
      category: wallpaper.category,
      primaryColor: wallpaper.primaryColor,
      resolution: wallpaper.resolution,
      width: wallpaper.width,
      height: wallpaper.height,
      fileSize: wallpaper.fileSize,
      downloadedAt: DateTime.now(),
    );

    await _box.put(wallpaper.wallhavenId, record.toMap());
  }

  static List<DownloadedWallpaper> getDownloads({String? searchQuery}) {
    final items = _box.values
        .map((e) => DownloadedWallpaper.fromMap(e))
        .toList();

    if (searchQuery == null || searchQuery.isEmpty) {
      return items;
    }

    final query = searchQuery.toLowerCase();
    return items.where((item) {
      return item.sourceQuery.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.primaryColor.toLowerCase().contains(query) ||
          item.resolution.toLowerCase().contains(query);
    }).toList();
  }

  static bool isDownloaded(String wallhavenId) {
    return _box.containsKey(wallhavenId);
  }

  static Future<void> removeDownload(String wallhavenId) async {
    final data = _box.get(wallhavenId);
    if (data != null) {
      final localPath = data['localPath'] as String?;
      if (localPath != null) {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await _box.delete(wallhavenId);
    }
  }

  static int get downloadCount => _box.length;
}
