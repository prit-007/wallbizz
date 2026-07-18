import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/backend_config.dart';

class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const NetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  String get _url => BackendConfig.proxyImageUrl(imageUrl);

  @override
  Widget build(BuildContext context) {
    final url = _url;

    if (kIsWeb) {
      return SizedBox(
        width: width,
        height: height,
        child: Image.network(
          url,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white24,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[900],
              child: const Icon(Icons.error_outline, color: Colors.white24),
            );
          },
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => Container(
        color: Colors.grey[900],
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white24,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[900],
        child: const Icon(Icons.error_outline, color: Colors.white24),
      ),
    );
  }
}
