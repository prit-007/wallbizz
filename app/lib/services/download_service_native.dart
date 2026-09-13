import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadService {
  static const _pathKey = 'download_path';

  static Future<String> get defaultDownloadPath async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/VivekWallpapers';
    final d = Directory(path);
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return path;
  }

  static Future<String> getDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_pathKey);
    if (custom != null && custom.isNotEmpty) {
      final d = Directory(custom);
      if (await d.exists()) return custom;
    }
    return defaultDownloadPath;
  }

  static Future<void> setDownloadPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pathKey, path);
  }

  static String fileNameFromUrl(String url) {
    final segments = Uri.parse(url).pathSegments;
    return segments.isNotEmpty ? segments.last : 'wallpaper.jpg';
  }

  static String _uniquePath(String dir, String name) {
    final file = File('$dir/$name');
    if (!file.existsSync()) return file.path;

    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    final ext = dot > 0 ? name.substring(dot) : '';

    for (int i = 1; i < 1000; i++) {
      final candidate = File('$dir/$base($i)$ext');
      if (!candidate.existsSync()) return candidate.path;
    }
    return file.path;
  }

  static Future<String> downloadImage({
    required String imageUrl,
    String? fileName,
    String? savePath,
    void Function(double progress)? onProgress,
  }) async {
    fileName ??= fileNameFromUrl(imageUrl);
    final dir = savePath ?? await getDownloadPath();
    final finalPath = _uniquePath(dir, fileName);

    final request = http.Request('GET', Uri.parse(imageUrl));
    final client = http.Client();
    final response = await client.send(request);

    if (response.statusCode != 200) {
      client.close();
      throw HttpException(
        'Download failed: HTTP ${response.statusCode}',
        uri: Uri.parse(imageUrl),
      );
    }

    final totalBytes = response.contentLength;
    final file = File(finalPath);
    final sink = file.openWrite();
    int received = 0;

    try {
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (totalBytes != null && totalBytes > 0) {
          onProgress?.call(received / totalBytes);
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
      client.close();
    }

    return finalPath;
  }
}
