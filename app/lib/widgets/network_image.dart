import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/backend_config.dart';
import '../config/theme_config.dart';

class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;

  const NetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
  });

  String get _url => BackendConfig.proxyImageUrl(imageUrl);

  @override
  Widget build(BuildContext context) {
    final vk = context.vivek;
    final url = _url;

    Widget buildPlaceholder() {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: vk.surfaceContainer),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: vk.shimmerHighlight);
    }

    if (kIsWeb) {
      return SizedBox(
        width: width,
        height: height,
        child: Image.network(
          url,
          fit: fit,
          cacheWidth: memCacheWidth,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child.animate().fade(duration: 400.ms, curve: Curves.easeOut);
            }
            return buildPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: vk.surfaceContainer,
            child: Icon(Icons.broken_image_rounded, color: vk.onSurfaceDim),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 400),
      fadeOutDuration: const Duration(milliseconds: 200),
      fadeInCurve: Curves.easeOutCubic,
      placeholder: (context, url) => buildPlaceholder(),
      errorWidget: (context, url, error) => Container(
        color: vk.surfaceContainer,
        child: Icon(Icons.broken_image_rounded, color: vk.onSurfaceDim),
      ),
    );
  }
}
