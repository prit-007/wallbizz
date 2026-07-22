class Wallpaper {
  final String id;
  final String wallhavenId;
  final String urlFull;
  final String urlThumb;
  final String resolution;
  final int width;
  final int height;
  final int fileSize;
  final String primaryColor;
  final String category;
  final String sourceQuery;
  final DateTime createdAt;

  Wallpaper({
    required this.id,
    required this.wallhavenId,
    required this.urlFull,
    required this.urlThumb,
    required this.resolution,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.primaryColor,
    required this.category,
    required this.sourceQuery,
    required this.createdAt,
  });

  double get aspectRatio => width / height;

  String get formattedFileSize {
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory Wallpaper.fromMap(Map<String, dynamic> map) {
    return Wallpaper(
      id: map['id'] ?? '',
      wallhavenId: map['wallhaven_id'] ?? '',
      urlFull: map['url_full'] ?? '',
      urlThumb: map['url_thumb'] ?? '',
      resolution: map['resolution'] ?? '',
      width: map['width'] ?? 0,
      height: map['height'] ?? 0,
      fileSize: map['file_size'] ?? 0,
      primaryColor: map['primary_color'] ?? '#000000',
      category: map['category'] ?? 'general',
      sourceQuery: map['source_query'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  factory Wallpaper.fromWallhavenMap(Map<String, dynamic> map) {
    final colors = map['colors'] as List<dynamic>?;
    final thumbs = map['thumbs'] as Map<String, dynamic>?;
    return Wallpaper(
      id: 'wh-${map['id'] ?? ''}',
      wallhavenId: map['id'] ?? '',
      urlFull: map['path'] ?? '',
      urlThumb: (thumbs?['small'] as String?) ?? (thumbs?['original'] as String?) ?? '',
      resolution: map['resolution'] ?? '',
      width: map['dimension_x'] ?? 0,
      height: map['dimension_y'] ?? 0,
      fileSize: map['file_size'] ?? 0,
      primaryColor: (colors != null && colors.isNotEmpty) ? colors[0] as String : '#000000',
      category: map['category'] ?? 'general',
      sourceQuery: '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
