import 'package:flutter/foundation.dart';

class BackendConfig {
  static String _baseUrl = 'https://wallbizz.onrender.com';

  static String get baseUrl => _baseUrl;

  static void init(String url) {
    _baseUrl = url;
  }

  static String proxyImageUrl(String imageUrl) {
    if (!kIsWeb) return imageUrl;
    return '$_baseUrl/api/v1/proxy-image?url=${Uri.encodeComponent(imageUrl)}';
  }
}
