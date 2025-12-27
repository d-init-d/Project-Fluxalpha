class Collection {
  final String id;
  final String name;
  final List<String> bookIds;
  final DateTime createdAt;

  const Collection({
    required this.id,
    required this.name,
    required this.bookIds,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bookIds': bookIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      name: json['name'] as String,
      bookIds: List<String>.from(json['bookIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Collection copyWith({
    String? id,
    String? name,
    List<String>? bookIds,
    DateTime? createdAt,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      bookIds: bookIds ?? this.bookIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
