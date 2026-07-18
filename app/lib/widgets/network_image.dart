import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/backend_config.dart';
import '../config/theme_config.dart';

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
    final vk = context.vivek;
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
              color: vk.surfaceContainer,
              child: Center(
                child: CircularProgressIndicator(
                  color: vk.onSurfaceDim,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: vk.surfaceContainer,
              child: Icon(Icons.error_outline, color: vk.onSurfaceDim),
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
        color: vk.surfaceContainer,
        child: Center(
          child: CircularProgressIndicator(
            color: vk.onSurfaceDim,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: vk.surfaceContainer,
        child: Icon(Icons.error_outline, color: vk.onSurfaceDim),
      ),
    );
  }
}
