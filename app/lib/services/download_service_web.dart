// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' show AnchorElement, Blob, Url, document;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DownloadService {
  static const _pathKey = 'download_path';

  static Future<String> get defaultDownloadPath async => '';

  static Future<String> getDownloadPath() async => '';

  static Future<void> setDownloadPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pathKey, path);
  }

  static String fileNameFromUrl(String url) {
    final segments = Uri.parse(url).pathSegments;
    return segments.isNotEmpty ? segments.last : 'wallpaper.jpg';
  }

  static Future<String> downloadImage({
    required String imageUrl,
    String? fileName,
    String? savePath,
    void Function(double progress)? onProgress,
  }) async {
    fileName ??= fileNameFromUrl(imageUrl);

    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }

    final blob = Blob([response.bodyBytes]);
    final objectUrl = Url.createObjectUrlFromBlob(blob);
    final anchor = AnchorElement(href: objectUrl)
      ..download = fileName
      ..style.display = 'none';
    document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    Url.revokeObjectUrl(objectUrl);

    return fileName;
  }
}
