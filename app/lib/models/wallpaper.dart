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

  double get aspectRatio => height == 0 ? 1.0 : width / height;

  String get formattedFileSize {
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory Wallpaper.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String? ?? '';
    final wallhavenId = map['wallhaven_id'] as String? ?? '';
    final urlFull = map['url_full'] as String? ?? '';
    if (id.isEmpty && wallhavenId.isEmpty) {
      throw FormatException('Wallpaper missing both id and wallhaven_id');
    }
    return Wallpaper(
      id: id,
      wallhavenId: wallhavenId,
      urlFull: urlFull,
      urlThumb: (map['url_thumb'] as String?) ?? '',
      resolution: (map['resolution'] as String?) ?? '',
      width: (map['width'] as int?) ?? 0,
      height: (map['height'] as int?) ?? 0,
      fileSize: (map['file_size'] as int?) ?? 0,
      primaryColor: (map['primary_color'] as String?) ?? '#000000',
      category: (map['category'] as String?) ?? 'general',
      sourceQuery: (map['source_query'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory Wallpaper.fromWallhavenMap(Map<String, dynamic> map) {
    final colors = map['colors'] as List<dynamic>?;
    final thumbs = map['thumbs'] as Map<String, dynamic>?;
    return Wallpaper(
      id: 'wh-${map['id'] ?? ''}',
      wallhavenId: map['id'] ?? '',
      urlFull: map['path'] ?? '',
      urlThumb:
          (thumbs?['small'] as String?) ??
          (thumbs?['original'] as String?) ??
          '',
      resolution: map['resolution'] ?? '',
      width: map['dimension_x'] ?? 0,
      height: map['dimension_y'] ?? 0,
      fileSize: map['file_size'] ?? 0,
      primaryColor: (colors != null && colors.isNotEmpty)
          ? colors[0] as String
          : '#000000',
      category: map['category'] ?? 'general',
      sourceQuery: '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
