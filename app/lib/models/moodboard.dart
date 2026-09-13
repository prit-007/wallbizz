class Moodboard {
  final String id;
  final String name;
  final int itemCount;
  final DateTime createdAt;

  Moodboard({
    required this.id,
    required this.name,
    this.itemCount = 0,
    required this.createdAt,
  });

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
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
