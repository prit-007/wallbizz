class DownloadedWallpaper {
  final String wallhavenId;
  final String localPath;
  final String urlFull;
  final String urlThumb;
  final String sourceQuery;
  final String category;
  final String primaryColor;
  final String resolution;
  final int width;
  final int height;
  final int fileSize;
  final DateTime downloadedAt;

  DownloadedWallpaper({
    required this.wallhavenId,
    required this.localPath,
    required this.urlFull,
    required this.urlThumb,
    required this.sourceQuery,
    required this.category,
    required this.primaryColor,
    required this.resolution,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.downloadedAt,
  });

  double get aspectRatio => width / height;

  String get formattedFileSize {
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'wallhavenId': wallhavenId,
      'localPath': localPath,
      'urlFull': urlFull,
      'urlThumb': urlThumb,
      'sourceQuery': sourceQuery,
      'category': category,
      'primaryColor': primaryColor,
      'resolution': resolution,
      'width': width,
      'height': height,
      'fileSize': fileSize,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory DownloadedWallpaper.fromMap(Map<dynamic, dynamic> map) {
    return DownloadedWallpaper(
      wallhavenId: map['wallhavenId'] ?? '',
      localPath: map['localPath'] ?? '',
      urlFull: map['urlFull'] ?? '',
      urlThumb: map['urlThumb'] ?? '',
      sourceQuery: map['sourceQuery'] ?? '',
      category: map['category'] ?? '',
      primaryColor: map['primaryColor'] ?? '#000000',
      resolution: map['resolution'] ?? '',
      width: map['width'] ?? 0,
      height: map['height'] ?? 0,
      fileSize: map['fileSize'] ?? 0,
      downloadedAt:
          DateTime.tryParse(map['downloadedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
