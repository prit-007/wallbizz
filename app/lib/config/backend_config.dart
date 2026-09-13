import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackendConfig {
  static String _baseUrl = '';

  static String get baseUrl => _baseUrl;

  static void init() {
    _baseUrl = dotenv.env['BACKEND_URL'] ?? '';
  }

  static String proxyImageUrl(String imageUrl) {
    if (_baseUrl.isEmpty || !kIsWeb) return imageUrl;
    return '$_baseUrl/api/v1/proxy-image?url=${Uri.encodeComponent(imageUrl)}';
  }
}
