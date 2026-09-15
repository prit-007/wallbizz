class Moodboard {
  final String id;
  final String name;
  final int itemCount;
  final DateTime createdAt;
  final List<String> wallhavenIds;

  Moodboard({
    required this.id,
    required this.name,
    this.itemCount = 0,
    required this.createdAt,
    this.wallhavenIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'item_count': itemCount,
      'wallhavenIds': wallhavenIds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Moodboard.fromMap(Map<dynamic, dynamic> map) {
    final rawIds = map['wallhavenIds'];
    final wallhavenIds = rawIds is List
        ? rawIds.map((e) => e.toString()).toList()
        : <String>[];
    return Moodboard(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      itemCount: map['item_count'] as int? ?? wallhavenIds.length,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      wallhavenIds: wallhavenIds,
    );
  }

  factory Moodboard.fromJson(Map<String, dynamic> json) {
    int itemCount = 0;
    final raw = json['item_count'];
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map) itemCount = (first['count'] as int?) ?? 0;
    } else if (raw is int) {
      itemCount = raw;
    }
    return Moodboard(
      id: json['id'] as String,
      name: json['name'] as String,
      itemCount: itemCount,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Moodboard && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
