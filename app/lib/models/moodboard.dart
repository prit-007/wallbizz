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
    return Moodboard(
      id: json['id'] as String,
      name: json['name'] as String,
      itemCount: json['item_count'] is Map
          ? ((json['item_count'] as Map?)?.values.first as int? ?? 0)
          : (json['item_count'] as int? ?? 0),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
